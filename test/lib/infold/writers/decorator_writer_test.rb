require 'test_helper'
require 'infold/writers/decorator_writer'
require 'infold/table'
require 'infold/field_group'
require 'infold/field'
require 'infold/resource'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    def setup
      @field_group = FieldGroup.new
      @resource = Resource.new('Product')
    end

    test "it should return boolean decorator_code" do
      @field_group.add_field('removed', :boolean)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def removed_display
          '<i class="bi bi-check-square-fill text-info"></i>'.html_safe if removed?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should return datetime decorator_code" do
      @field_group.add_field('delivered_at', :datetime)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def delivered_at_display
          delivered_at ? I18n.l(delivered_at) : ''
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should return date decorator_code" do
      @field_group.add_field('stock_date', :date)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def stock_date_display
          stock_date ? I18n.l(stock_date) : ''
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int and config have options(digit and append), it should return number decorator_code" do
      field = @field_group.add_field('price', :integer)
      field.build_decorator(append: 'YEN', digit: true)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def price_display
          "\#{price.to_formatted_s(:delimited)\}YEN" if price.present?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int and config have options(digit and prepend), it should return number decorator_code" do
      field = @field_group.add_field('price', :integer)
      field.build_decorator(prepend: '$', digit: true)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        def price_display
          "$\#{price.to_formatted_s(:delimited)\}" if price.present?
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have int but config have no option, it should return blank" do
      @field_group.add_field('price', :integer)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      assert_nil(code)
    end

    test "if columns have int, float or decimal fields, decorator_code should return number_code" do
      field = @field_group.add_field('price1', :integer)
      field.build_decorator(digit: true)
      field = @field_group.add_field('price2', :float)
      field.build_decorator(digit: true)
      field = @field_group.add_field('price3', :decimal)
      field.build_decorator(digit: true)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
      code = writer.decorator_code
      expect_int_code = "def price1_display"
      expect_float_code = "def price2_display"
      expect_decimal_code = "def price3_display"
      assert_match(expect_int_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match(expect_float_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match(expect_decimal_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "if columns have string and config have options(prepend), decorator_code should return string_code" do
      field = @field_group.add_field('name', :string)
      field.build_decorator(prepend: 'NAME:')
      @field_group.add_field('description', :string)
      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
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
      field = @field_group.add_field('status', :integer)
      enum = field.build_enum
      enum.add_elements(key: 'ordered', value: 1, color: 'red')
      enum.add_elements(key: 'charged', value: 2, color: 'blue')
      field.build_decorator(kind: :enum)

      field = @field_group.add_field('category', :integer)
      enum = field.build_enum
      enum.add_elements(key: 'kitchen', value: 1)
      enum.add_elements(key: 'dining', value: 2)
      field.build_decorator(kind: :enum)

      @resource.field_group = @field_group
      writer = DecoratorWriter.new(@resource)
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