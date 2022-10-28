# require '/test/test_helper'
require 'infold/writers/model_writer'
require 'infold/resource_config'
require 'infold/db_schema'
require 'hashie'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      @db_schema = DbSchema.new
    end

    test "In association_code, if setting.associations is not defined, it will be nil" do
      setting = Hashie::Mash.new
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "In association_code, If resource.associations is defined, but empty, it will be nil" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: nil, has_one: nil, belongs_to: nil } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "In association_code, resource.associations corresponds to has_many, has_one, belongs_to" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: ['children'], has_one: ['child'], belongs_to: ['parent'] } }
      resource_config = ResourceConfig.new('product', setting)
      db_schema = DbSchema.new
      writer = ModelWriter.new(resource_config, db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :children")
      assert_includes(code, "has_one :child")
      assert_includes(code, "belongs_to :parent")
    end

    test "In association_code, if resource.associations is defined in hash, it will be an association with options" do
      setting = Hashie::Mash.new
      setting.model = {
        associations: {
          has_many: {
            one_details: { class_name: 'OneDetail', dependent: 'destroy'},
            two_details: { class_name: 'TwoDetail', dependent: 'destroy'},
          }
        }
      }
      resource_config = ResourceConfig.new('product', setting)
      db_schema = DbSchema.new
      writer = ModelWriter.new(resource_config, db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :one_details, class_name: 'OneDetail', dependent: 'destroy'")
      assert_includes(code, "has_many :two_details, class_name: 'TwoDetail', dependent: 'destroy'")
    end

    test "In association_code, If resource.form contains associations, accepts_nested_attributes_for will reflect" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: %w(one_details two_details) } }
      setting.app = { form: { fields: [ { one_details: %w(id name) } ] } }
      resource_config = ResourceConfig.new('product', setting)
      db_schema = DbSchema.new
      writer = ModelWriter.new(resource_config, db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :one_details")
      assert_includes(code, "accepts_nested_attributes_for :one_details")
      refute_includes(code, "accepts_nested_attributes_for :two_details")
    end
  end
end