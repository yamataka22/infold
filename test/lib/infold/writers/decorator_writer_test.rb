require 'test_helper'
require 'infold/writers/decorator_writer'
require 'infold/resource'
require 'infold/db_schema'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      @resource = Resource.new("product", {})
    end

    test "if columns have boolean field, decorator_code should return boolean_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.boolean "removed", null: false, default: false
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', {}, db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def removed_display
          '<i class="bi bi-check-square-fill text-info"></i>'.html_safe if removed?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have datetime field, decorator_code should return datetime_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivered_at"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', {}, db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def delivered_at_display
          delivered_at ? I18n.l(delivered_at) : ''
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have date field, decorator_code should return date_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.date "stock_date"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', {}, db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def stock_date_display
          stock_date ? I18n.l(stock_date) : ''
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int and config have options(digit and append), decorator_code should return number_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.integer "price", null: false, default: 0
        end
      RUBY
      yaml = <<-"YAML"
        model:
          decorate:
            price:
              append: "YEN"
              digit: true
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def price_display
          "\#{price.to_formatted_s(:delimited)\}YEN" if price.present?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int and config have options(digit and prepend), decorator_code should return number_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.integer "price", null: false, default: 0
        end
      RUBY
      yaml = <<-"YAML"
        model:
          decorate:
            price:
              prepend: "$"
              digit: true
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def price_display
          "$\#{price.to_formatted_s(:delimited)\}" if price.present?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int but config have no option, decorator_code should return blank" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.integer "price", null: false, default: 0
        end
      RUBY
      yaml = <<-"YAML"
        model:
          decorate:
            price:
              prepend: "$"
              digit: true
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def price_display
          "$\#{price.to_formatted_s(:delimited)\}" if price.present?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int, float or decimal fields, decorator_code should return number_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.integer "stock", null: false, default: 0
          t.float "price"
          t.decimal "weight"
        end
      RUBY
      yaml = <<-"YAML"
        model:
          decorate:
            stock:
              digit: true
            price:
              digit: true
            weight:
              digit: true
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_int_code = "def stock_display"
      expect_float_code = "def price_display"
      expect_decimal_code = "def weight_display"
      assert_match(expect_int_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match(expect_float_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match(expect_decimal_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have string and config have options(prepend), decorator_code should return string_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.string "description", null: false, default: 0
        end
      RUBY
      yaml = <<-"YAML"
        model:
          decorate:
            name:
              prepend: "NAME:"
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def name_display
          "NAME:\#{name\}" if name.present?
        end
      RUBY
      unexpect_code = "def description_display"
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
      refute_match(unexpect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if color defined enum in resource yaml, decorator_code should return enum_code" do
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.integer "status"
          t.integer "category"
        end
      RUBY
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered:
                value: 1
                color: red
              charged:
                value: 2
                color: blue
            category:
              kitchen: 1
              dining: 2
      YAML
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      writer = DecoratorWriter.new(resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def status_color
          case status.to_s
          when 'ordered' then 'red'
          when 'charged' then 'blue'
          else ''
          end
        end
      RUBY
      unexpect_code = 'def category_color'
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
      refute_match(unexpect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end
  end
end