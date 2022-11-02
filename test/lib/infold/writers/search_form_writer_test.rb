require 'test_helper'
require 'infold/writers/search_form_writer'
require 'infold/resource'
require 'infold/db_schema'

module Infold
  class SearchFormWriterTest < ::ActiveSupport::TestCase

    setup do
      @resource = Resource.new("product", {})
    end

    test "set_conditions_code should generate set condition each field" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id: eq
              - name: full_like
              - status: any
          association_search:
            conditions:
              - id: eq
              - status: eq
              - price: gteq
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = SearchFormWriter.new(resource)
      code = writer.set_conditions_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        set_condition :id_eq,
          :name_full_like,
          :status_any,
          :status_eq,
          :price_gteq
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
      resource = Resource.new('product', YAML.load(yaml))
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
      resource = Resource.new('product', YAML.load(yaml))
      writer = SearchFormWriter.new(resource)
      code = writer.record_search_include_code
      assert_nil(code)
    end
  end
end