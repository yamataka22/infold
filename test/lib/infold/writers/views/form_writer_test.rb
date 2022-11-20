require 'test_helper'
require 'infold/writers/views/form_writer'
require 'infold/table'
require 'infold/field_group'
require 'infold/field'
require 'infold/resource'

module Infold
  module Views
    class FormWriterTest < ::ActiveSupport::TestCase

      def setup
        @field_group = FieldGroup.new
        @resource = Resource.new('Product')
      end

      test "If form is a select type, form_field_code should be return select field" do
        field = @field_group.add_field('parent_id')
        field.build_association(kind: :belongs_to,
                                table: Table.new('parents'),
                                class_name: 'ParentClass',
                                name: 'parent',
                                name_field: 'name')
        field.build_form_element(form_kind: 'select')

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :parent_id, :select, " +
                       "list: Admin::ParentClass.all.pluck(:name, :id), selected_value: form.object.parent_id)", code)
      end

      test "If form is a association type, form_field_code should be return association field" do
        field = @field_group.add_field('parent_id')
        field.build_association(kind: :belongs_to,
                                table: Table.new('parents'),
                                name: 'parent',
                                name_field: 'name')
        field.build_form_element(form_kind: 'association_search')

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :parent_id, :association_search, " +
                       "association_name: :parent, search_path: admin_parents_path, name_field: :parent_name)", code)
      end

      test "If form is a enum type and form_kind is a select type, form_field_code should be return select field" do
        field = @field_group.add_field('status')
        enum = field.build_enum
        enum.add_elements(key: :ordered, value: 1)
        enum.add_elements(key: :charged, value: 2)
        enum.add_elements(key: :delivered, value: 3)
        field.build_form_element(form_kind: :select)

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :status, :select, " +
                       "list: Admin::Product.statuses_i18n.invert, selected_value: form.object.status)", code)
      end

      test "If form is a boolean type, form_field_code should be return switch field" do
        field = @field_group.add_field('removed', :boolean)
        field.build_form_element(form_kind: :switch)

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :removed, :switch)", code)
      end

      test "If form is a date type, form_field_code should be return text field with datepicker" do
        field = @field_group.add_field('published_on', :date)
        field.build_form_element

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :published_on, :text, datepicker: true)", code)
      end

      test "If form is a datetime type, form_field_code should be return datetime field" do
        field = @field_group.add_field('delivered_at', :datetime)
        field.build_form_element

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :delivered_at, :datetime)", code)
      end

      test "If field has decorator(prepend), form_field_code should be return text with prepend" do
        field = @field_group.add_field('price', :int)
        field.build_decorator(prepend: '$', digit: true)
        field.build_form_element

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :price, :text, prepend: '$')", code)
      end

      test "If field has decorator(append), form_field_code should be return text with append" do
        field = @field_group.add_field('price', :int)
        field.build_decorator(append: 'YEN', digit: true)
        field.build_form_element

        @resource.field_group = @field_group
        writer = FormWriter.new(@resource)
        code = writer.form_field_code(field)
        assert_equal("= render Admin::FieldsetComponent.new(form, :price, :text, append: 'YEN')", code)
      end

    end
  end
end