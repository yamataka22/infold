require 'test_helper'
require 'infold/writers/search_form_writer'
require 'infold/property/resource'
require 'infold/db_schema'

module Infold
  class SearchFormWriterTest < ::ActiveSupport::TestCase

    test "set_conditions_code should generate set condition each field" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id:
                  sign: eq
              - name:
                  sign: full_like
              - status:
                   sign: any
          association_search:
            conditions:
              - id:
                  sign: eq
              - status:
                  sign: eq
              - price:
                  sign: gteq
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = SearchFormWriter.new(resource)
      code = writer.set_conditions_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        set_condition :id_eq,
          :name_full_like,
          :price_gteq,
          :status_any,
          :status_eq
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "record_search_include_code should generate 'include belongs_to associations'" do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
            one_parent:
              kind: belongs_to
            two_parent:
              kind: belongs_to
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.bigint "one_parent_id"
          t.bigint "two_parent_id"
        end
        create_table "details" do |t|
          t.bigint "product_id"
        end
        create_table "one_parents" do |t|
          t.string "name"
        end
        create_table "two_parents" do |t|
          t.string "name"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = SearchFormWriter.new(resource)
      code = writer.record_search_include_code
      assert_match("includes(:one_parent, :two_parent)", code)
      refute_match("details", code)
    end

    test "if belongs_to association is blank, record_search_include_code should return nil" do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.bigint "one_parent_id"
          t.bigint "two_parent_id"
        end
        create_table "details" do |t|
          t.bigint "product_id"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = SearchFormWriter.new(resource)
      code = writer.record_search_include_code
      assert_nil(code)
    end
  end
end