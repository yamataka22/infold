# require '/test/test_helper'
require 'infold/writers/model_writer'
require 'infold/model_config'
require 'infold/db_schema'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      @model_config = ModelConfig.new('product', {})
      @app_config = AppConfig.new('product', {})
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "association_code should be nil if setting.associations is not defined" do
      writer = ModelWriter.new(@model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "association_code should be nil if resource.associations is defined but empty" do
      yaml = <<-"YAML"
        model:
          association:
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_nil(code)
    end

    test "association_code should generate has_many, has_one, belongs_to" do
      yaml = <<-"YAML"
        model:
          association:
            children:
              kind: has_many
            child:
              kind: has_one
            parent:
              kind: belongs_to
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_match("has_many :children", code)
      assert_match("has_one :child", code)
      assert_match("belongs_to :parent", code)
    end

    test "association_code should generate association with options if resource.associations defined in hash" do
      yaml = <<-"YAML"
        model:
          association:
            one_details:
              kind: has_many
              class_name: 'OneDetail'
              dependent: 'destroy'
            two_details:
              kind: has_many
              class_name: 'TwoDetail'
              dependent: 'destroy'
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_match("has_many :one_details, class_name: 'OneDetail', dependent: 'destroy'", code)
      assert_match("has_many :two_details, class_name: 'TwoDetail', dependent: 'destroy'", code)
    end

    test "association_code should generate accepts_nested_attributes_for if resource.form contains associations" do
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
      model_config = ModelConfig.new('product', YAML.load(yaml))

      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.association_code
      assert_match("has_many :one_details", code)
      assert_match("accepts_nested_attributes_for :one_details", code)
      refute_match("accepts_nested_attributes_for :two_details", code)
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
      writer = ModelWriter.new(@model_config, @app_config, db_schema)
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.active_storage_attachment_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        has_one_attached :image
        attr_accessor :remove_image
        before_validation { self.image = nil if remove_image.to_s == '1' }
      CODE
      assert_match(expect_code, code.gsub(/^\s+/, ''))
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.active_storage_attachment_code
      expect_code = <<-CODE.gsub(/^        /, '')
        has_one_attached :image do |attachable|
        [TAB]attachable.variant :thumb, resize_to_fit: [100, 200]
        end
        attr_accessor :remove_image
      CODE
      assert_match(expect_code, code.gsub(/^\s+/, ''))
    end

    test "validation_code should generate presence validates" do
      yaml = <<-"YAML"
        model:
          validate:
            stock: presence
      YAML
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.validation_code
      assert_match("validates :stock, presence: true", code.gsub(/^\s+/, ''))
      assert_match("validates :name, presence: true, uniqueness: true", code.gsub(/^\s+/, ''))
      assert_match("validates :price, allow_blank: true, uniqueness: true", code.gsub(/^\s+/, ''))
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.validation_code
      assert_match("validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }",
                   code.gsub(/^\s+/, ''))
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
      model_config = ModelConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(model_config, @app_config, @db_schema)
      code = writer.enum_code
      assert_match("enum status: { ordered: 1, charged: 2 }, _prefix: true", code.gsub(/^\s+/, ''))
      assert_match("enum category: { kitchen: 1, living: 2 }, _prefix: true", code.gsub(/^\s+/, ''))
    end

    test "scope_code should generate scope (only index_conditions, except datetime)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id: eq
              - name: full_like
              - price: gteq
              - price: lteq
              - status: any
              - address: start_with
      YAML
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(@db_config, app_config, @db_schema)
      expect_code = <<-CODE.gsub(/^\s+/, '')
        scope :id_eq, ->(v) do
        [TAB]where(id: v) if v.present?
        end
      CODE
      code = writer.scope_code
      scopes = code.split("scope")
      assert_equal(expect_code.gsub('scope ', ''), scopes[1].gsub(/^\s+/, ''))
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
      assert_match('where(arel_table[:price].lteq(v)) if v.present?', code)
      assert_match('where(arel_table[:price].gteq(v)) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:address].matches("#{v}%")) if v.present?', code)
    end

    test "scope_code should generate scope (index_conditions and association_conditions, except datetime)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id: eq
              - status: any
          association_search:
            conditions:
              - id: eq
              - name: full_like
      YAML
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = ModelWriter.new(@db_config, app_config, @db_schema)
      code = writer.scope_code
      scopes = code.split("scope")
      assert_equal(4, scopes.size)
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
    end

    test "scope_code should generate scope (about datetime)" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - delivery_at: eq
              - delivery_at: lteq
      YAML
      app_config = AppConfig.new('product', YAML.load(yaml))
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
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))

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
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end
  end
end