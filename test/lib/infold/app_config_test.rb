# require '/test/test_helper'
require 'infold/app_config'

module Infold
  class AppConfigTest < ::ActiveSupport::TestCase
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
      app_config = AppConfig.new('product', YAML.load(yaml))
      index_conditions = app_config.index_conditions
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
      app_config = AppConfig.new('product', YAML.load(yaml))
      association_search_conditions = app_config.association_search_conditions
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
      app_config = AppConfig.new('product', YAML.load(yaml))
      form_fields = app_config.form_fields
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
  end
end