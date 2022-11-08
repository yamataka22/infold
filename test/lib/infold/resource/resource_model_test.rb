require 'test_helper'
require 'infold/property/resource'

module Infold
  class ResourceModelTest < ::ActiveSupport::TestCase
    def setup
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
        end
      RUBY
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "model_associations should be return ModelAssociation" do
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
              dependent: destroy
            two_details:
              kind: has_many
              class_name: TwoDetail
            three_detail:
              kind: has_one
            parent:
              kind: belongs_to
              foreign_key: parent_id
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.bigint "parent_id"
          t.string "name"
        end
        create_table "one_details" do |t|
          t.bigint "product_id"
        end
        create_table "two_details" do |t|
          t.bigint "product_id"
        end
        create_table "three_details" do |t|
          t.bigint "product_id"
        end
        create_table "parents" do |t|
          t.integer "kind"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      associations = resource.associations
      assert_equal(4, associations.size)
      assert_equal('parent', associations[0].association_name)
      assert(associations[0].belongs_to?)
      assert_equal('parent_id', associations[0].field.name)
      assert_equal('one_details', associations[1].association_name)
      assert(associations[1].has_many?)
      assert_equal('destroy', associations[1].dependent)
      assert_equal('two_details', associations[2].association_name)
      assert_equal('TwoDetail', associations[2].class_name)
      assert_equal('three_detail', associations[3].association_name)
      assert(associations[3].has_one?)
    end

    test "active_storage should be return ActiveStorage (no thumb)" do
      yaml = <<-"YAML"
        model:
          active_storage:
            product_image:
              kind: image
            pdf:
              kind: file
      YAML
      resource = Resource.new('product', YAML.load(yaml), @db_schema)
      active_storage_fields = resource.active_storage_fields
      assert_equal(2, active_storage_fields.size)
      field = active_storage_fields[0]
      assert_equal('product_image', field.name)
      assert_equal('image', field.active_storage.kind)
      assert_nil(field.active_storage.thumb)
      field = active_storage_fields[1]
      assert_equal('pdf', field.name)
      assert_equal('file', field.active_storage.kind)
      assert_nil(field.active_storage.thumb)
    end

    test "active_storages should be return ActiveStorage with thumb" do
      yaml = <<-"YAML"
        model:
          active_storage:
            product_image:
              kind: image
              thumb:
                kind: fill
                width: 100
                height: 200
      YAML
      resource = Resource.new('product', YAML.load(yaml), @db_schema)
      active_storage_fields = resource.active_storage_fields
      assert_equal(1, active_storage_fields.size)
      assert_equal('product_image', active_storage_fields[0].name )
      thumb = active_storage_fields[0].active_storage.thumb
      assert_equal('fill', thumb.kind)
      assert_equal(100, thumb.width)
      assert_equal(200, thumb.height)
    end

    test "validation_fields should be return Validate" do
      yaml = <<-"YAML"
        model:
          validate:
            stock: presence
            title:
              - presence
              - uniqueness
            price:
              - presence
              - numericality:
                  greater_than_or_equal_to: 0
                  less_than_or_equal_to: 100
      YAML
      resource = Resource.new('product', YAML.load(yaml), @db_schema)
      validation_fields = resource.validation_fields

      assert_equal(3, validation_fields.size)
      assert_equal('stock', validation_fields[0].name)
      conditions = validation_fields[0].validation.conditions
      assert_equal(:presence, conditions[0].condition)

      assert_equal('title', validation_fields[1].name)
      conditions = validation_fields[1].validation.conditions
      assert_equal(:presence, conditions[0].condition)
      assert_equal(:uniqueness, conditions[1].condition)

      assert_equal('price', validation_fields[2].name)
      conditions = validation_fields[2].validation.conditions
      assert_equal(:presence, conditions[0].condition)
      assert_equal(:numericality, conditions[1].condition)
      assert_equal({ 'greater_than_or_equal_to' => 0, 'less_than_or_equal_to' => 100 }, conditions[1].options)
    end

    test "enum should be return Enum (has no color)" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
      YAML
      resource = Resource.new('product', YAML.load(yaml), @db_schema)
      enum_fields = resource.enum_fields
      assert_equal(1, enum_fields.size)
      assert_equal('status', enum_fields[0].name)
      assert_equal(3, enum_fields[0].enum.elements.size)
      assert_equal('ordered', enum_fields[0].enum.elements[0].key)
      assert_equal(1, enum_fields[0].enum.elements[0].value)
    end

    test "enum should be return Enum (with color)" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
            category:
              kitchen:
                value: 1
                color: red
              dining:
                value: 2
                color: blue
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.integer "status"
          t.integer "category"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      enum_fields = resource.enum_fields
      assert_equal(2, enum_fields.size)
      assert_equal('status', enum_fields[0].name)
      assert_equal(3, enum_fields[0].enum.elements.size)
      assert_equal('category', enum_fields[1].name)
      assert_equal(2, enum_fields[1].enum.elements.size)
      assert_equal(1, enum_fields[1].enum.elements[0].value)
      assert_equal('red', enum_fields[1].enum.elements[0].color)
      assert_equal(2, enum_fields[1].enum.elements[1].value)
      assert_equal('blue', enum_fields[1].enum.elements[1].color)
    end

    test "decorator should be return Decorator" do
      yaml = <<-"YAML"
        model:
          decorator:
            price:
              append: "YEN"
              digit: true
            name:
              prepend: "PRODUCT:"
          enum:
            status:
              ordered: 1
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.integer "price"
          t.string "name"
          t.integer "status"
          t.datetime "published_at"
          t.date "sell_until"
          t.boolean "removed"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      decorator_fields = resource.decorator_fields
      assert_equal(6, decorator_fields.size)

      assert_equal('price', decorator_fields[0].name)
      assert_equal(:number, decorator_fields[0].decorator.kind)
      assert_equal('YEN', decorator_fields[0].decorator.append)
      assert(decorator_fields[0].decorator.digit)

      assert_equal('name', decorator_fields[1].name)
      assert_equal(:string, decorator_fields[1].decorator.kind)
      assert_equal('PRODUCT:', decorator_fields[1].decorator.prepend)

      assert_equal('status', decorator_fields[2].name)
      assert_equal(:enum, decorator_fields[2].decorator.kind)

      assert_equal('published_at', decorator_fields[3].name)
      assert_equal(:datetime, decorator_fields[3].decorator.kind)

      assert_equal('sell_until', decorator_fields[4].name)
      assert_equal(:date, decorator_fields[4].decorator.kind)

      assert_equal('removed', decorator_fields[5].name)
      assert_equal(:boolean, decorator_fields[5].decorator.kind)
    end
  end
end