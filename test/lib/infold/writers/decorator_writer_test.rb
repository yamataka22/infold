# require '/test/test_helper'
require 'infold/writers/decorator_writer'
require 'infold/model_config'
require 'infold/db_schema'
require 'hashie'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      setting = Hashie::Mash.new
      @app_config = AppConfig.new('products', setting)
      @model_config = ModelConfig.new('products', setting)
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "if columns have boolean field, decorator_code should return boolean_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.boolean "removed", null: false, default: false
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      writer = DecoratorWriter.new(@model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def removed_display
        [TAB]'<i class="bi bi-check-square-fill text-info"></i>'.html_safe if removed?
        end
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "if columns have datetime field, decorator_code should return datetime_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivered_at"
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      writer = DecoratorWriter.new(@model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def delivered_at_display
        [TAB]delivered_at ? I18n.l(delivered_at) : ''
        end
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "if columns have date field, decorator_code should return date_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.date "stock_date"
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      writer = DecoratorWriter.new(@model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def stock_date_display
        [TAB]stock_date ? I18n.l(stock_date) : ''
        end
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "if columns have int and config have options(digit and append), decorator_code should return number_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.integer "price", null: false, default: 0
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      setting = Hashie::Mash.new
      setting.model = { decorates: { price: { digit: true, append: '!!' } } }
      model_config = ModelConfig.new('product', setting)
      writer = DecoratorWriter.new(model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def price_display
        [TAB]"\#{price.to_formatted_s(:delimited)\}!!" if price.present?
        end
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "if columns have int and config have options(digit and prepend), decorator_code should return number_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.integer "price", null: false, default: 0
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      setting = Hashie::Mash.new
      setting.model = { decorates: { price: { digit: true, prepend: '$' } } }
      model_config = ModelConfig.new('product', setting)
      writer = DecoratorWriter.new(model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def price_display
        [TAB]"$\#{price.to_formatted_s(:delimited)\}" if price.present?
        end
      CODE
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "if columns have int but config have no option, decorator_code should return blank" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.integer "price", null: false, default: 0
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      setting = Hashie::Mash.new
      setting.model = { decorates: { stock: { digit: true, prepend: '$' } } }
      model_config = ModelConfig.new('product', setting)
      writer = DecoratorWriter.new(model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def price_display
        [TAB]"$\#{price.to_formatted_s(:delimited)\}" if price.present?
        end
      CODE
      refute_includes(code.gsub(/^\s+/, ''), expect_code)
    end

    test "if columns have int, float or decimal fields, decorator_code should return number_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.integer "stock", null: false, default: 0
          t.float "price"
          t.decimal "weight"
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      setting = Hashie::Mash.new
      setting.model = { decorates: { stock: { digit: true }, price: { digit: true }, weight: { digit: true } } }
      model_config = ModelConfig.new('product', setting)
      writer = DecoratorWriter.new(model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_int_code = "def stock_display"
      expect_float_code = "def price_display"
      expect_decimal_code = "def weight_display"
      assert_includes(code.gsub(/^\s+/, ''), expect_int_code)
      assert_includes(code.gsub(/^\s+/, ''), expect_float_code)
      assert_includes(code.gsub(/^\s+/, ''), expect_decimal_code)
    end

    test "if columns have string and config have options(prepend), decorator_code should return string_code" do
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.string "description", null: false, default: 0
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      setting = Hashie::Mash.new
      setting.model = { decorates: { name: { prepend: 'NAME:' } } }
      model_config = ModelConfig.new('product', setting)
      writer = DecoratorWriter.new(model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def name_display
        [TAB]"NAME:\#{name\}" if name.present?
        end
      CODE
      unexpect_code = "def description_display"
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
      refute_includes(code.gsub(/^\s+/, ''), unexpect_code)
    end

    test "if color defined enum in resource yaml, decorator_code should return enum_code" do
      setting = Hashie::Mash.new
      setting.model = { enum: {
        status: {
          ordered: {
            value: 1,
            color: 'red'
          },
          charged: {
            value: 2,
            color: 'blue'
          }
        },
        category: {
          kitchen: 1,
          living: 2
        }
      } }
      model_config = ModelConfig.new('product', setting)
      db_schema_content = <<-"SCHEMA"
        create_table "products" do |t|
          t.string "name"
          t.integer "status"
          t.integer "category"
        end
      SCHEMA
      db_schema = DbSchema.new(db_schema_content)
      writer = DecoratorWriter.new(model_config, @app_config, db_schema)
      code = writer.decorator_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        def status_color
        [TAB]case status.to_s
        [TAB]when 'ordered' then 'red'
        [TAB]when 'charged' then 'blue'
        [TAB]else ''
        [TAB]end
        end
      CODE
      unexpect_code = 'def category_color'
      assert_includes(code.gsub(/^\s+/, ''), expect_code)
      refute_includes(code.gsub(/^\s+/, ''), unexpect_code)
    end
  end
end