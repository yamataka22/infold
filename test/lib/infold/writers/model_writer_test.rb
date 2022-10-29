# require '/test/test_helper'
require 'infold/writers/model_writer'
require 'infold/resource_config'
require 'infold/db_schema'
require 'hashie'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "association_code should be nil if setting.associations is not defined" do
      setting = Hashie::Mash.new
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "association_code should be nil if resource.associations is defined but empty" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: nil, has_one: nil, belongs_to: nil } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "association_code should generate has_many, has_one, belongs_to" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: ['children'], has_one: ['child'], belongs_to: ['parent'] } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :children")
      assert_includes(code, "has_one :child")
      assert_includes(code, "belongs_to :parent")
    end

    test "association_code should generate association with options if resource.associations defined in hash" do
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
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :one_details, class_name: 'OneDetail', dependent: 'destroy'")
      assert_includes(code, "has_many :two_details, class_name: 'TwoDetail', dependent: 'destroy'")
    end

    test "association_code should generate accepts_nested_attributes_for if resource.form contains associations" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: %w(one_details two_details) } }
      setting.app = { form: { fields: [ { one_details: %w(id name) } ] } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :one_details")
      assert_includes(code, "accepts_nested_attributes_for :one_details")
      refute_includes(code, "accepts_nested_attributes_for :two_details")
    end
    
    test "datetime_field_code should generate except timestamp filed" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivery_at", null: false
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      setting = Hashie::Mash.new
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, db_schema)
      code = writer.datetime_field_code
      assert_includes(code, "datetime_field :delivery_at")
      refute_includes(code, "datetime_field :created_at")
      refute_includes(code, "datetime_field :updated_at")
    end

    test "active_storage_attachment_code should generate active_storage field" do
      setting = Hashie::Mash.new
      setting.model = { active_storage: { image: { kind: 'image' }, pdf: nil } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.active_storage_attachment_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        has_one_attached :image
        attr_accessor :remove_image
        before_validation { self.image = nil if remove_image.to_s == '1' }
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
      assert_includes(code, "has_one_attached :pdf")
    end

    test "active_storage_attachment_code should generate active_storage field with thumb" do
      setting = Hashie::Mash.new
      setting.model = { active_storage: { image: { kind: 'image', thumb: { kind: 'fit', width: 100, height: 200 } }, pdf: nil } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.active_storage_attachment_code
      expect_code = <<-CODE.gsub(/^        /, '')
        has_one_attached :image do |attachable|
        [TAB]attachable.variant :thumb, resize_to_fit: [100, 200]
        end
        attr_accessor :remove_image
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "validation_code should generate presence validates" do
      setting = Hashie::Mash.new
      setting.model = { validates: { stock: 'presence' } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.validation_code
      assert_equal(code.gsub(/^\s+|\n/, ''), "validates :stock, presence: true")
    end

    test "validation_code should generate multiple validates" do
      setting = Hashie::Mash.new
      setting.model = { validates: { stock: 'presence', name: %w(presence uniqueness), price: 'uniqueness' } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.validation_code
      assert_includes(code.gsub(/^\s+/, ''), "validates :stock, presence: true")
      assert_includes(code.gsub(/^\s+/, ''), "validates :name, presence: true, uniqueness: true")
      assert_includes(code.gsub(/^\s+/, ''), "validates :price, allow_blank: true, uniqueness: true")
    end

    test "validation_code should generate validates include options" do
      setting = Hashie::Mash.new
      setting.model = { validates: { price: [ 'presence', numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 } ] } }
      resource_config = ResourceConfig.new('product', setting)
      writer = ModelWriter.new(resource_config, @db_schema)
      code = writer.validation_code
      assert_includes(code.gsub(/^\s+/, ''), "validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }")
    end
  end
end