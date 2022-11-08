require 'test_helper'
require 'infold/writers/model_writer'
require 'infold/property/resource'
require 'infold/db_schema'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      @resource = Resource.new("product", {})
    end

    test "association_code should generate has_many, has_one, belongs_to" do
      yaml = <<-"YAML"
        model:
          association:
            one_children:
              kind: has_many
            two_child:
              kind: has_one
            parent:
              kind: belongs_to
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.bigint "parent_id"
        end
        create_table "one_children" do |t|
          t.bigint "product_id"
        end
        create_table "two_children" do |t|
          t.bigint "product_id"
        end
        create_table "parents" do |t|
          t.name "parent_name"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = ModelWriter.new(resource)
      code = writer.association_code
      assert_match("has_many :one_children", code)
      assert_match("has_one :two_child", code)
      assert_match("belongs_to :parent", code)
    end

    test "association_code should generate association with options if resource.associations defined in hash" do
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
              foreign_key: 'one_detail_id'
              dependent: 'destroy'
            two_details:
              kind: has_many
              class_name: 'TwoDetail'
              dependent: 'delete_all'
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
        end
        create_table "one_details" do |t|
          t.bigint "product_id"
        end
        create_table "two_details" do |t|
          t.bigint "product_id"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = ModelWriter.new(resource)
      code = writer.association_code
      assert_match("has_many :one_details, foreign_key: 'one_detail_id', dependent: :destroy", code)
      assert_match("has_many :two_details, class_name: 'TwoDetail', dependent: :delete_all", code)
    end

    test "accepts_nested_attributes_code should generate accepts_nested_attributes_for if resource.form contains associations" do
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
            two_details:
              kind: has_many
        app:
          form:
            fields:
              - one_details:
                  kind: associations
                  fields:
                    - id
                    - name
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
        end
        create_table "one_details" do |t|
          t.bigint "product_id"
        end
        create_table "two_details" do |t|
          t.bigint "product_id"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = ModelWriter.new(resource)
      code = writer.accepts_nested_attributes_code
      assert_match("accepts_nested_attributes_for :one_details", code)
      refute_match("accepts_nested_attributes_for :two_details", code)
    end
    
    test "datetime_field_code should generate except timestamp filed" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivery_at", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', {}, db_schema)
      writer = ModelWriter.new(resource)
      code = writer.datetime_field_code
      assert_match("datetime_field :delivery_at", code)
      refute_match("datetime_field :created_at", code)
      refute_match("datetime_field :updated_at", code)
    end

    test "active_storage_attachment_code should generate active_storage field" do
      yaml = <<-"YAML"
        model:
          active_storage:
            image:
              kind: image
            pdf:
              kind: file
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.active_storage_attachment_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        has_one_attached :image
        attr_accessor :remove_image
        before_validation { self.image = nil if remove_image.to_s == '1' }
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("has_one_attached :pdf", code)
    end

    test "active_storage_attachment_code should generate active_storage field with thumb" do
      yaml = <<-"YAML"
        model:
          active_storage:
            image:
              kind: image
              thumb:
                kind: fit
                width: 100
                height: 200
            pdf:
              kind: file
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.active_storage_attachment_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        has_one_attached :image do |attachable|
          attachable.variant :thumb, resize_to_fit: [100, 200]
        end
        attr_accessor :remove_image
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "validation_code should generate presence validates" do
      yaml = <<-"YAML"
        model:
          validate:
            stock: presence
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.validation_code
      assert_equal("validates :stock, presence: true", code.gsub(/^\s+|\n/, ''))
    end

    test "validation_code should generate multiple validates" do
      yaml = <<-"YAML"
        model:
          validate:
            stock: presence
            name:
              - presence
              - uniqueness
            price:
              - uniqueness
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.validation_code
      assert_match("validates :stock, presence: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("validates :name, presence: true, uniqueness: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("validates :price, allow_blank: true, uniqueness: true", code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "validation_code should generate validates include options" do
      yaml = <<-"YAML"
        model:
          validate:
            price:
              - presence
              - numericality:
                  greater_than_or_equal_to: 0
                  less_than_or_equal_to: 100
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.validation_code
      assert_match("validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }",
                   code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "enum_code should generate enum" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
            category:
              kitchen: 1
              living: 2
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.enum_code
      assert_match("enum status: { ordered: 1, charged: 2 }, _prefix: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("enum category: { kitchen: 1, living: 2 }, _prefix: true", code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "scope_code should generate scope (only index_conditions, except datetime)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id:
                  sign: eq
              - name:
                  sign: full_like
              - price:
                  sign: gteq
              - company_id:
                  sign: eq
                  form_kind: association
              - status:
                  sign: any
              - address:
                  sign: start_with
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.scope_code
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
      assert_match('where(company_id: v) if v.present?', code)
      assert_match('where(arel_table[:price].gteq(v)) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:address].matches("#{v}%")) if v.present?', code)
    end

    test "scope_code should generate scope (index_conditions and association_conditions, except datetime)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id:
                  sign: eq
              - company_id:
                  sign: eq
                  form_kind: association
              - status:
                  sign: any
          association_search:
            conditions:
              - id: 
                  sign: eq
              - name:
                  sign: full_like
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      writer = ModelWriter.new(resource)
      code = writer.scope_code
      assert_equal(4, code.scan('scope').size)
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
    end

    test "scope_code should generate scope (about datetime)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - delivery_at:
                  sign: eq
              - delivery_at:
                  sign: lteq
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivery_at", null: false
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = ModelWriter.new(resource)
      code = writer.scope_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        scope :delivery_at_eq, ->(v) do
          return if v.blank?
          begin
            where(delivery_at: v.to_date.all_day)
          rescue
            where(arel_table[:delivery_at].eq(v))
          end
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))

      expect_code = <<-RUBY.gsub(/^\s+/, '')
        scope :delivery_at_lteq, ->(v) do
          return if v.blank?
          begin
            v = v.to_date.next_day
          rescue
          end
          where(arel_table[:delivery_at].lteq(v))
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end
  end
end