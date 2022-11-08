require 'test_helper'
require 'infold/property/resource'

module Infold
  class ResourceAppTest < ::ActiveSupport::TestCase
    test "index_conditions should be return IndexCondition" do
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
      resource = Resource.new('product', YAML.load(yaml))
      index_condition_fields = resource.condition_fields(:index)
      assert_equal(2, index_condition_fields.size)
      assert_equal('id', index_condition_fields[0].name)
      assert_equal(:eq, index_condition_fields[0].search_conditions[0].sign)

      assert_equal('price', index_condition_fields[1].name)
      assert_equal(2, index_condition_fields[1].search_conditions.size)
      assert_equal(:lteq, index_condition_fields[1].search_conditions[0].sign)
      assert_equal('number', index_condition_fields[1].search_conditions[0].index_form_kind)
      assert_equal(:gteq, index_condition_fields[1].search_conditions[1].sign)
      assert_equal('text', index_condition_fields[1].search_conditions[1].index_form_kind)
    end

    test "association_search_conditions should be return AssociationCondition" do
      yaml = <<-"YAML"
        app:
          association_search:
            conditions:
              - id:
                  sign: eq
              - company_id:
                  sign: eq
                  form_kind: association
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      association_search_condition_fields = resource.condition_fields(:association_search)
      assert_equal(2, association_search_condition_fields.size)
      assert_equal('id', association_search_condition_fields[0].name)
      assert_equal(:eq, association_search_condition_fields[0].search_conditions[0].sign)
      assert_equal('company_id', association_search_condition_fields[1].name)
      assert_equal(:eq, association_search_condition_fields[1].search_conditions[0].sign)
      assert_equal('association', association_search_condition_fields[1].search_conditions[0].association_search_form_kind)
    end

    test "form_element_fields should be return FormField" do
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
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      form_element_fields = resource.form_element_fields
      assert_equal(3, form_element_fields.size)
      assert_equal('title', form_element_fields[0].name)
      assert_equal('description', form_element_fields[1].name)
      assert_equal(:textarea, form_element_fields[1].form_element.form_kind)
      assert_equal('details', form_element_fields[2].name)
      assert_equal(:association, form_element_fields[2].form_element.form_kind)
      assert_equal(2, form_element_fields[2].form_element.association_fields.size)
      assert_equal('amount', form_element_fields[2].form_element.association_fields[0].name)
      assert_equal('unit_price', form_element_fields[2].form_element.association_fields[1].name)
      assert_equal(:number, form_element_fields[2].form_element.association_fields[1].form_element.form_kind)
    end

    test "index_default_order and association_search_default_order should be return DefaultOrder" do
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
      resource = Resource.new('product', YAML.load(yaml))
      index_default_order = resource.index_default_order
      assert_equal('id', index_default_order.field.name)
      assert_equal('asc', index_default_order.order_kind)
      association_default_order = resource.association_search_default_order
      assert_equal('name', association_default_order.field.name)
      assert_equal('desc', association_default_order.order_kind)
    end

    test "if default_order is blank, index_default_order and association_search_default_order should be return nil" do
      yaml = <<-"YAML"
        app:
          index:
            list:
              default_order:
          association_search:
            list:
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      index_default_order = resource.index_default_order
      association_default_order = resource.association_search_default_order
      assert_nil(index_default_order)
      assert_nil(association_default_order)
    end

    test "index_list_fields should be return index list fields" do
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
      resource = Resource.new('product', YAML.load(yaml))
      index_list_fields = resource.index_list_fields
      assert_equal(3, index_list_fields.size)
      assert_equal('name', index_list_fields[1].name)

      association_search_list_fields = resource.association_search_list_fields
      assert_equal(2, association_search_list_fields.size)
      assert_equal('address', association_search_list_fields[1].name)
    end

    test "index_list_fields should be return table top several columns if index list field is blank" do
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
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      index_list_fields = resource.index_list_fields
      assert_equal(5, index_list_fields.size)
      assert_equal('category', index_list_fields[1].name)
      assert_equal('created_at', index_list_fields[4].name)

      association_search_list_fields = resource.association_search_list_fields
      assert_equal(2, association_search_list_fields.size)
      assert_equal('category', association_search_list_fields[1].name)
    end
  end
end