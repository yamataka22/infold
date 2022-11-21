require 'test_helper'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  class YamlReaderTest < ::ActiveSupport::TestCase
    def setup
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
        end
      RUBY
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "it should be return fields with active_storage (no thumb)" do
      yaml = <<-"YAML"
        model:
          active_storage:
            product_image:
              kind: image
            pdf:
              kind: file
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      active_storages = resource.field_group.active_storage_fields.map(&:active_storage)
      assert_equal(2, active_storages.size)
      assert_equal('product_image', active_storages[0].field.name)
      assert_equal('image', active_storages[0].kind)
      assert_nil(active_storages[0].thumb)
      assert_equal('pdf', active_storages[1].field.name)
      assert_equal('file', active_storages[1].kind)
      assert_nil(active_storages[1].thumb)
    end

    test "it should be return fields with active_storage (with thumb)" do
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
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      active_storages = resource.field_group.active_storage_fields.map(&:active_storage)
      assert_equal(1, active_storages.size)
      assert_equal('product_image', active_storages[0].field.name )
      thumb = active_storages[0].thumb
      assert_equal('fill', thumb.kind)
      assert_equal(100, thumb.width)
      assert_equal(200, thumb.height)
    end

    test "it should be return fields with validations" do
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
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      validations = resource.field_group.validation_fields.map(&:validation)

      assert_equal(3, validations.size)
      assert_equal('stock', validations[0].field.name)
      assert_equal(:presence, validations[0].conditions[0].condition)

      assert_equal('title', validations[1].field.name)
      assert_equal(:presence, validations[1].conditions[0].condition)
      assert_equal(:uniqueness, validations[1].conditions[1].condition)

      assert_equal('price', validations[2].field.name)
      assert_equal(:presence, validations[2].conditions[0].condition)
      assert_equal(:numericality, validations[2].conditions[1].condition)
      assert_equal(0, validations[2].conditions[1].options[:greater_than_or_equal_to])
      assert_equal(100, validations[2].conditions[1].options[:less_than_or_equal_to])
    end

    test "it should be return fields with enum (no color)" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      enums = resource.field_group.enum_fields.map(&:enum)
      assert_equal(1, enums.size)
      assert_equal('status', enums[0].field.name)
      assert_equal(3, enums[0].elements.size)
      assert_equal('ordered', enums[0].elements[0].key)
      assert_equal(1, enums[0].elements[0].value)
    end

    test "it should be return fields with enum (with color)" do
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
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      enums = resource.field_group.enum_fields.map(&:enum)
      assert_equal(2, enums.size)
      assert_equal('status', enums[0].field.name)
      assert_equal(3, enums[0].elements.size)
      assert_equal('category', enums[1].field.name)
      assert_equal(2, enums[1].elements.size)
      assert_equal(1, enums[1].elements[0].value)
      assert_equal('red', enums[1].elements[0].color)
      assert_equal(2, enums[1].elements[1].value)
      assert_equal('blue', enums[1].elements[1].color)
    end

    test "it should be return fields with decorator" do
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
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      decorators = resource.field_group.decorator_fields.map(&:decorator)
      assert_equal(3, decorators.size)

      assert_equal('price', decorators[0].field.name)
      assert_equal(:number, decorators[0].kind)
      assert_equal('YEN', decorators[0].append)
      assert(decorators[0].digit)

      assert_equal('name', decorators[1].field.name)
      assert_equal(:string, decorators[1].kind)
      assert_equal('PRODUCT:', decorators[1].prepend)

      assert_equal('status', decorators[2].field.name)
      assert_equal(:enum, decorators[2].kind)
    end

    test "it should be return fields with search conditions (index)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id:
                  sign: eq
              - price:
                  sign: lteq
                  form_kind: number
              - price:
                  sign: gteq
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      conditions = resource.field_group.conditions(:index)
      assert_equal(3, conditions.size)
      assert_equal('id', conditions[0].field.name)
      assert_equal(:eq, conditions[0].sign)
      assert(conditions[1].in_index?)

      assert_equal('price', conditions[1].field.name)
      assert_equal(:lteq, conditions[1].sign)
      assert_equal('number', conditions[1].index_form_kind)
      assert_equal(:gteq, conditions[2].sign)
      assert_equal('text', conditions[2].index_form_kind)
    end

    test "it should be return fields with search conditions (association search)" do
      yaml = <<-"YAML"
        app:
          association_search:
            conditions:
              - id:
                  sign: eq
              - stock:
                  sign: gteq
                  form_kind: number
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      conditions = resource.field_group.conditions(:association_search)
      assert_equal(2, conditions.size)
      assert_equal('id', conditions[0].field.name)
      assert_equal(:eq, conditions[0].sign)
      assert_equal('stock', conditions[1].field.name)
      assert_equal(:gteq, conditions[1].sign)
      assert_equal('number', conditions[1].association_search_form_kind)
    end

    test "if index and association search conditions are mixed, it should be return merged search conditions" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id:
                  sign: eq
              - price:
                  sign: lteq
                  form_kind: number
          association_search:
            conditions:
              - price:
                  sign: lteq
                  form_kind: text
              - price:
                  sign: gteq
                  form_kind: number
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      conditions = resource.field_group.conditions
      assert_equal(3, conditions.size)
      assert_equal('id', conditions[0].field.name)
      assert_equal(:eq, conditions[0].sign)
      assert(conditions[0].in_index?)
      assert(!conditions[0].in_association_search?)
      assert_equal('price', conditions[1].field.name)
      assert_equal(:lteq, conditions[1].sign)
      assert(conditions[1].in_index?)
      assert(conditions[1].in_association_search?)
      assert_equal('number', conditions[1].index_form_kind)
      assert_equal('text', conditions[1].association_search_form_kind)
      assert_equal('price', conditions[2].field.name)
      assert_equal(:gteq, conditions[2].sign)
      assert(!conditions[2].in_index?)
      assert(conditions[2].in_association_search?)
      assert_equal('number', conditions[2].association_search_form_kind)
    end

    test "it should be return default order" do
      yaml = <<-"YAML"
        app:
          index:
            list:
              default_order:
                field: id
                kind: asc
          association_search:
            list:
              default_order:
                field: name
                kind: desc
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      default_order = resource.default_order
      assert_equal('id', default_order.field.name)
      assert_equal('asc', default_order.order_kind)
    end

    test "if default_order is blank, it should be return nil" do
      yaml = <<-"YAML"
        app:
          index:
            list:
              default_order:
          association_search:
            list:
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      assert_nil(resource.default_order)
    end

    test "it should be return fields with index list" do
      yaml = <<-"YAML"
        app:
          index:
            list:
              fields:
                - id
                - name
                - address
          association_search:
            list:
              fields:
                - id
                - address
      YAML
      resource = YamlReader.generate_resource('products', YAML.load(yaml), @db_schema)
      list_fields = resource.field_group.index_list_fields

      index_list_fields = list_fields.select(&:in_index_list?)
      assert_equal(3, index_list_fields.size)
      assert_equal('name', index_list_fields[1].name)

      association_search_list_fields = list_fields.select(&:in_association_search_list?)
      assert_equal(2, association_search_list_fields.size)
      assert_equal('address', association_search_list_fields[1].name)
    end

    test "if index list is blank, it should be return table top several fields" do
      yaml = <<-"YAML"
        app:
          index:
            list:
          association_search:
            list:
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "category"
          t.string "name"
          t.datetime "delivery_at", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      index_list_fields = resource.field_group.index_list_fields
      assert_equal(5, index_list_fields.size)
      assert_equal('category', index_list_fields[1].name)
      assert_equal('created_at', index_list_fields[4].name)

      association_search_list_fields = resource.field_group.association_search_list_fields
      assert_equal(2, association_search_list_fields.size)
      assert_equal('category', association_search_list_fields[1].name)
    end

    test "it should be return fields with show element" do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
          active_storage:
            image:
              kind: image
            pdf:
              kind: file
        app:
          show:
            fields:
              - name
              - price
              - details:
                  fields:
                    - color
                    - stock
              - image
              - pdf
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.float "price"
        end
        create_table "details" do |t|
          t.bigint "product_id"
          t.string "color"
          t.integer "stock"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      show_fields = resource.field_group.show_fields
      assert_equal(5, show_fields.size)
      assert_equal('name', show_fields[0].name)
      assert_equal('price', show_fields[1].name)
      assert_equal('details', show_fields[2].name)
      assert(show_fields[2].show_element.kind_association?)
      association_fields = show_fields[2].show_element.association_fields
      assert_equal(2, association_fields.size)
      assert_equal('color', association_fields[0].name)
      assert_equal('stock', association_fields[1].name)
      assert_equal('image', show_fields[3].name)
      assert(show_fields[3].active_storage.kind_image?)
      assert_equal('pdf', show_fields[4].name)
      assert(show_fields[4].active_storage.kind_file?)
    end

    test "if show element is blank, show fields should be return all fields" do
      yaml = <<-"YAML"
        app:
          show:
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.float "price"
          t.integer "stock"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      show_fields = resource.field_group.show_fields
      assert_equal(6, show_fields.size)
      assert_equal('id', show_fields[0].name)
      assert_equal('name', show_fields[1].name)
      assert_equal('updated_at', show_fields[5].name)
    end

    test "it should be return fields with form element" do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
        app:
          form:
            fields:
              - title
              - description:
                  kind: textarea
              - details:
                  kind: association
                  fields:
                    - amount
                    - unit_price:
                        kind: number
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "title"
          t.integer "description"
        end

        create_table "details" do |t|
          t.bigint "product_id"
          t.string "amount"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      form_fields = resource.field_group.form_fields
      assert_equal(3, form_fields.size)
      assert_equal('title', form_fields[0].name)
      assert_equal('description', form_fields[1].name)
      assert_equal(:textarea, form_fields[1].form_element.form_kind)
      assert_equal('details', form_fields[2].name)
      assert_equal(:association, form_fields[2].form_element.form_kind)
      association_fields = form_fields[2].form_element.association_fields
      assert_equal(2, association_fields.size)
      assert_equal('amount', association_fields[0].name)
      assert_equal('unit_price', association_fields[1].name)
      assert_equal(:number, association_fields[1].form_element.form_kind)
    end

    test "it should be return fields with associations" do
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
      resource = YamlReader.generate_resource('products', YAML.load(yaml), db_schema)
      associations = resource.field_group.associations
      assert_equal(4, associations.size)
      assert_equal('parent', associations[0].name)
      assert(associations[0].belongs_to?)
      assert_equal('parent_id', associations[0].field.name)
      assert_equal('one_details', associations[1].name)
      assert(associations[1].has_many?)
      assert_equal('destroy', associations[1].dependent)
      assert_equal('two_details', associations[2].name)
      assert_equal('TwoDetail', associations[2].class_name)
      assert_equal('three_detail', associations[3].name)
      assert(associations[3].has_one?)
    end

    test "If there are settings such as validate in the has_many association, they should be reflected in the association.field_group." do
      yaml = <<-"YAML"
        model:
          association:
            details:
              kind: has_many
              class_name: PurchaseDetail
              dependent: destroy
              model:
                validate:
                  product_id: presence
                  amount: presence
                decorator:
                  amount:
                    digit: true
                association:
                  product:
                    kind: belongs_to
      YAML
      db_schema_content = <<-"RUBY"
        create_table "purchases" do |t|
          t.bigint "customer_id"
        end
        create_table "purchase_details" do |t|
          t.bigint "purchase_id"
          t.bigint "product_id"
          t.integer "amount"
        end
        create_table "products" do |t|
          t.string "name"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = YamlReader.generate_resource('purchase', YAML.load(yaml), db_schema)
      associations = resource.field_group.associations
      assert_equal(1, associations.size)
      assert_equal('details', associations[0].name)
      assert_equal('PurchaseDetail', associations[0].class_name)
      assert_equal('purchase_details', associations[0].table.name)
      assert_equal(4, associations[0].field_group.count)

      product_id_field = associations[0].field_group.fields[2]
      assert_equal('product_id', product_id_field.name)
      assert_equal('product', product_id_field.association.name)
      assert(product_id_field.association.belongs_to?)
      assert_equal(:presence, product_id_field.validation.conditions[0].condition)

      amount_field = associations[0].field_group.fields[3]
      assert_equal(:presence, amount_field.validation.conditions[0].condition)
      assert(amount_field.decorator.digit)
    end
  end
end