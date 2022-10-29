# require '/test/test_helper'
require 'infold/app_config'
require 'hashie'

module Infold
  class AppConfigTest < ::ActiveSupport::TestCase
    test "index_conditions should be return IndexCondition" do
      setting = Hashie::Mash.new
      setting.app = { index: { conditions: { id: 'eq', title: 'full_like' } } }
      app_config = AppConfig.new('product', setting)
      index_conditions = app_config.index_conditions
      assert_equal(index_conditions.size, 2)
      assert_equal(index_conditions[0].field, 'id')
      assert_equal(index_conditions[0].sign, 'eq')
      assert_equal(index_conditions[1].field, 'title')
      assert_equal(index_conditions[1].sign, 'full_like')
    end

    test "index_conditions should be return IndexCondition (multiple signs)" do
      setting = Hashie::Mash.new
      setting.app = { index: { conditions: { id: 'eq', price: %w(lteq gteq) } } }
      app_config = AppConfig.new('product', setting)
      index_conditions = app_config.index_conditions
      assert_equal(index_conditions.size, 3)
      assert_equal(index_conditions[0].field, 'id')
      assert_equal(index_conditions[1].field, 'price')
      assert_equal(index_conditions[1].sign, 'lteq')
      assert_equal(index_conditions[2].field, 'price')
      assert_equal(index_conditions[2].sign, 'gteq')
    end

    test "association_search_conditions should be return AssociationCondition" do
      setting = Hashie::Mash.new
      setting.app = { association_search: { conditions: { name: 'start_with' } } }
      app_config = AppConfig.new('product', setting)
      association_search_conditions = app_config.association_search_conditions
      assert_equal(association_search_conditions.size, 1)
      assert_equal(association_search_conditions[0].field, 'name')
      assert_equal(association_search_conditions[0].sign, 'start_with')
    end

    test "association_search_conditions should be return IndexCondition (multiple signs)" do
      setting = Hashie::Mash.new
      setting.app = { association_search: { conditions: { id: 'eq', price: %w(lteq gteq) } } }
      app_config = AppConfig.new('product', setting)
      association_search_conditions = app_config.association_search_conditions
      assert_equal(association_search_conditions.size, 3)
      assert_equal(association_search_conditions[0].field, 'id')
      assert_equal(association_search_conditions[1].field, 'price')
      assert_equal(association_search_conditions[1].sign, 'lteq')
      assert_equal(association_search_conditions[2].field, 'price')
      assert_equal(association_search_conditions[2].sign, 'gteq')
    end
  end
end