require 'test_helper'
require 'infold/writers/views/index_writer'
require 'infold/table'
require 'infold/field_group'
require 'infold/field'
require 'infold/resource'

module Infold
  module Views
    class IndexWriterTest < ::ActiveSupport::TestCase

      def setup
        @field_group = FieldGroup.new
        @resource = Resource.new('Product')
      end

      test "condition has association_search, condition_form_code should be return FieldsetComponent(:association)" do
        field = @field_group.add_field('parent_id')
        field.build_association(kind: :belongs_to,
                                table: Table.new('parents'),
                                name: 'parent',
                                name_field: 'name')
        field.add_search_condition(:index, sign: :eq, form_kind: 'association_search')

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :parent_id_eq, :association_search, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:parent_id), " +
                       "association_name: :parent, search_path: admin_parents_path(name_field: :name), name_field: :parent_name)",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has select association, condition_form_code should be return select component" do
        field = @field_group.add_field('parent_id')
        field.build_association(kind: :belongs_to,
                                table: Table.new('parents'),
                                class_name: 'ParentClass',
                                name: 'parent',
                                name_field: 'name')
        field.add_search_condition(:index, sign: :eq, form_kind: 'select')

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :parent_id_eq, :select, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:parent_id), " +
                       "list: Admin::ParentClass.all.pluck(:name, :id), selected_value: form.object.parent_id_eq)",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has select enum, condition_form_code should be return select component" do
        field = @field_group.add_field('status')
        enum = field.build_enum
        enum.add_elements(key: :ordered, value: 1)
        enum.add_elements(key: :charged, value: 2)
        enum.add_elements(key: :delivered, value: 3)
        field.add_search_condition(:index, sign: :eq, form_kind: :select)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :status_eq, :select, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:status), " +
                       "list: Admin::Product.statuses_i18n.invert, selected_value: form.object.status_eq)",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has any enum, condition_form_code should be return checkbox component" do
        field = @field_group.add_field('status')
        enum = field.build_enum
        enum.add_elements(key: :ordered, value: 1)
        enum.add_elements(key: :charged, value: 2)
        enum.add_elements(key: :delivered, value: 3)
        field.add_search_condition(:index, sign: :any, form_kind: :checkbox)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :status_any, :checkbox, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:status), " +
                       "list: Admin::Product.statuses_i18n, checked_values: form.object.status_any)",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has boolean, condition_form_code should be return switch component" do
        field = @field_group.add_field('removed', :boolean)
        field.add_search_condition(:index, sign: :eq, form_kind: :switch)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :removed_eq, :switch, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:removed), " +
                       "include_hidden: false)",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has date, condition_form_code should be return text with datepicker" do
        field = @field_group.add_field('published_on', :date)
        field.add_search_condition(:index, sign: :gteq, form_kind: :text)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :published_on_gteq, :text, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:published_on), " +
                       "datepicker: true, placeholder: '#{condition.sign_label}')",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has datetime, condition_form_code should be return text with datepicker" do
        field = @field_group.add_field('delivered_at', :datetime)
        field.add_search_condition(:index, sign: :lteq, form_kind: :text)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :delivered_at_lteq, :text, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:delivered_at), " +
                       "datepicker: true, placeholder: '#{condition.sign_label}')",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has decorator(prepend), condition_form_code should be return text with prepend" do
        field = @field_group.add_field('price', :int)
        field.build_decorator(prepend: '$', digit: true)
        field.add_search_condition(:index, sign: :eq, form_kind: :text)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :price_eq, :text, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:price), " +
                       "prepend: '$', placeholder: '#{condition.sign_label}')",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "condition has decorator(append), condition_form_code should be return text with prepend" do
        field = @field_group.add_field('price', :int)
        field.build_decorator(append: 'YEN', digit: true)
        field.add_search_condition(:index, sign: :eq, form_kind: :text)

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        condition = @resource.conditions.first
        code = writer.condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :price_eq, :text, alignment: false, " +
                       "label: Admin::Product.human_attribute_name(:price), " +
                       "append: 'YEN', placeholder: '#{condition.sign_label}')",
                     code.gsub(/\[TAB\]|\n/, ''))
      end

      test "list_header_code should be return field code" do
        %w(id name category).each_with_index do |name, seq|
          field = @field_group.add_field(name)
          field.index_list_seq = seq
        end

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        list_field = @resource.index_list_fields.last
        code = writer.list_header_code(list_field)
        assert_equal("= render Admin::SortableComponent.new(@search, :category, " +
                       "label: Admin::Product.human_attribute_name(:category))",
                     code)
      end

      test "csv_field_code should convert enum to i18n" do
        field = @field_group.add_field('category', :int)
        enum = field.build_enum
        enum.add_elements(key: :kitchen, value: 1)
        field.csv_seq = 0

        field = @field_group.add_field('price', :int)
        field.csv_seq = 1

        @resource.field_group = @field_group
        writer = IndexWriter.new(@resource)
        csv_fields = @resource.csv_fields
        code = writer.csv_field_code(csv_fields[0])
        assert_equal("product.category_i18n", code)
        code = writer.csv_field_code(csv_fields[1])
        assert_equal("product.price", code)
      end
    end
  end
end