# require '/test/test_helper'
require 'infold/writers/model_writer'
require 'infold/model_config'
require 'infold/db_schema'
require 'hashie'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      setting = Hashie::Mash.new
      @app_config = AppConfig.new('resource', setting)
      @model_config = ModelConfig.new('resource', setting)
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "association_code should be nil if setting.associations is not defined" do
      setting = Hashie::Mash.new
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "association_code should be nil if resource.associations is defined but empty" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: nil, has_one: nil, belongs_to: nil } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "association_code should generate has_many, has_one, belongs_to" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: ['children'], has_one: ['child'], belongs_to: ['parent'] } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
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
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_includes(code, "has_many :one_details, class_name: 'OneDetail', dependent: 'destroy'")
      assert_includes(code, "has_many :two_details, class_name: 'TwoDetail', dependent: 'destroy'")
    end

    test "association_code should generate accepts_nested_attributes_for if resource.form contains associations" do
      setting = Hashie::Mash.new
      setting.model = { associations: { has_many: %w(one_details two_details) } }
      setting.app = { form: { fields: [ { one_details: %w(id name) } ] } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
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
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, db_schema)
      code = writer.datetime_field_code
      assert_includes(code, "datetime_field :delivery_at")
      refute_includes(code, "datetime_field :created_at")
      refute_includes(code, "datetime_field :updated_at")
    end

    test "active_storage_attachment_code should generate active_storage field" do
      setting = Hashie::Mash.new
      setting.model = { active_storage: { image: { kind: 'image' }, pdf: nil } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
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
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
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
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.validation_code
      assert_equal(code.gsub(/^\s+|\n/, ''), "validates :stock, presence: true")
    end

    test "validation_code should generate multiple validates" do
      setting = Hashie::Mash.new
      setting.model = { validates: { stock: 'presence', name: %w(presence uniqueness), price: 'uniqueness' } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.validation_code
      assert_includes(code.gsub(/^\s+/, ''), "validates :stock, presence: true")
      assert_includes(code.gsub(/^\s+/, ''), "validates :name, presence: true, uniqueness: true")
      assert_includes(code.gsub(/^\s+/, ''), "validates :price, allow_blank: true, uniqueness: true")
    end

    test "validation_code should generate validates include options" do
      setting = Hashie::Mash.new
      setting.model = { validates: { price: [ 'presence', numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 } ] } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.validation_code
      assert_includes(code.gsub(/^\s+/, ''), "validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }")
    end

    test "enum_code should generate enum" do
      setting = Hashie::Mash.new
      setting.model = { enum: { status: { ordered: 1, charged: 2 },
                                category: { kitchen: { value: 1, color: 'red' }, living: { value: 2, color: 'blue' } } } }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.enum_code
      assert_includes(code.gsub(/^\s+/, ''), "enum status: { ordered: 1, charged: 2 }, _prefix: true")
      assert_includes(code.gsub(/^\s+/, ''), "enum category: { kitchen: 1, living: 2 }, _prefix: true")
    end

    test "scope_code should generate scope (only index_conditions, except datetime)" do
      setting = Hashie::Mash.new
      setting.app = { index: {
        conditions: {
          id: 'eq',
          name: 'full_like',
          price: %w(lteq gteq),
          status: 'any',
          address: 'start_with',
        } } }
      app_config = AppConfig.new('product', setting)
      writer = ModelWriter.new(@db_config, app_config, @db_schema)
      expect_code = <<-CODE.gsub(/^\s+/, '')
        scope :id_eq, ->(v) do
        [TAB]where(id: v) if v.present?
        end
      CODE
      code = writer.scope_code
      scopes = code.split("scope")
      assert_equal(scopes[1].gsub(/^\s+/, ''), expect_code.gsub('scope ', ''))
      assert_includes(code, 'where(arel_table[:name].matches("%#{v}%")) if v.present?')
      assert_includes(code, 'where(arel_table[:price].lteq(v)) if v.present?')
      assert_includes(code, 'where(arel_table[:price].gteq(v)) if v.present?')
      assert_includes(code, 'where(status: v) if v.present?')
      assert_includes(code, 'where(arel_table[:address].matches("#{v}%")) if v.present?')
    end

    test "scope_code should generate scope (index_conditions and association_conditions, except datetime)" do
      setting = Hashie::Mash.new
      setting.app = {
        index: { conditions: {
          id: 'eq',
          status: 'any',
        } },
        association_search: { conditions: {
          id: 'eq',
          name: 'full_like',
        } }
      }
      app_config = AppConfig.new('product', setting)
      writer = ModelWriter.new(@db_config, app_config, @db_schema)
      code = writer.scope_code
      scopes = code.split("scope")
      assert_equal(scopes.size, 4)
      assert_includes(code, 'where(id: v) if v.present?')
      assert_includes(code, 'where(status: v) if v.present?')
      assert_includes(code, 'where(arel_table[:name].matches("%#{v}%")) if v.present?')
    end

    test "scope_code should generate scope (about datetime)" do
      setting = Hashie::Mash.new
      setting.app = { index: { conditions: { delivery_at: %w(eq lteq) } } }
      app_config = AppConfig.new('product', setting)
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivery_at", null: false
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      writer = ModelWriter.new(@db_config, app_config, db_schema)
      code = writer.scope_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        scope :delivery_at_eq, ->(v) do
          return if v.blank?
          begin
            where(delivery_at: v.to_date.all_day)
          rescue
            where(arel_table[:delivery_at].eq(v))
          end
        end
      CODE
      assert_includes(code.gsub(/^\s+|\[TAB\]/, ''), expect_code)

      expect_code = <<-CODE.gsub(/^\s+/, '')
        scope :delivery_at_lteq, ->(v) do
          return if v.blank?
          begin
            v = v.to_date.next_day
          rescue
          end
          where(arel_table[:delivery_at].lteq(v))
        end
      CODE
      assert_includes(code.gsub(/^\s+|\[TAB\]/, ''), expect_code)
    end
  end
end