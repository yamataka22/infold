require 'test_helper'
require 'infold/resource'

module Infold
  class ResourceAppTest < ::ActiveSupport::TestCase
    test "index_conditions should be return IndexCondition" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id: eq
              - title: full_like
              - price: gteq
              - price: lteq
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      index_conditions = resource.index_conditions
      assert_equal(4, index_conditions.size)
      assert_equal('id', index_conditions[0].field)
      assert_equal('eq', index_conditions[0].sign)
      assert_equal('title', index_conditions[1].field)
      assert_equal('full_like', index_conditions[1].sign)
      assert_equal('price', index_conditions[2].field)
      assert_equal('gteq', index_conditions[2].sign)
      assert_equal('price', index_conditions[3].field)
      assert_equal('lteq', index_conditions[3].sign)
    end

    test "association_search_conditions should be return AssociationCondition" do
      yaml = <<-"YAML"
        app:
          association_search:
            conditions:
              - id: eq
              - price: gteq
              - price: lteq
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      association_search_conditions = resource.association_search_conditions
      assert_equal(3, association_search_conditions.size)
      assert_equal('id', association_search_conditions[0].field)
      assert_equal('eq', association_search_conditions[0].sign)
      assert_equal('price', association_search_conditions[1].field)
      assert_equal('gteq', association_search_conditions[1].sign)
      assert_equal('price', association_search_conditions[2].field)
      assert_equal('lteq', association_search_conditions[2].sign)
    end

    test "form_fields should be return FormField" do
      yaml = <<-"YAML"
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
      resource = Resource.new('product', YAML.load(yaml))
      form_fields = resource.form_fields
      assert_equal(3, form_fields.size)
      assert_equal('title', form_fields[0].field)
      assert_equal('description', form_fields[1].field)
      assert_equal('textarea', form_fields[1].kind)
      assert_equal('details', form_fields[2].field)
      assert_equal('association', form_fields[2].kind)
      assert_equal(2, form_fields[2].association_fields.size)
      assert_equal('amount', form_fields[2].association_fields[0].field)
      assert_equal('unit_price', form_fields[2].association_fields[1].field)
      assert_equal('number', form_fields[2].association_fields[1].kind)
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
      assert_equal({ :field => 'id', :kind => 'asc' }, index_default_order.to_h)
      association_default_order = resource.association_search_default_order
      assert_equal({ :field => 'name', :kind => 'desc' }, association_default_order.to_h)
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
  end
end