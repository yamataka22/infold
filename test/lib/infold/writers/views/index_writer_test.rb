require 'test_helper'
require 'infold/writers/views/index_writer'
require 'infold/table'
require 'infold/field'
require 'infold/resource'

module Infold
  module Views
    class IndexWriterTest < ::ActiveSupport::TestCase
  
      test "condition has association_search, search_condition_form_code should be return FieldsetComponent(:association)" do
        fields = []
        field = Field.new('parent_id')
        field.build_association(kind: :belongs_to,
                                association_table: Table.new('parents'),
                                name: 'parent',
                                name_field: 'name')
        field.add_search_condition(:index, sign: :eq, form_kind: 'association_search')
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :parent_id_eq, :association_search, " +
                    "association_name: :parent, search_path: admin_parents_path, name_field: :parent_name)", code)
      end
  
      test "condition has select association, search_condition_form_code should be return select component" do
        fields = []
        field = Field.new('parent_id')
        field.build_association(kind: :belongs_to,
                                association_table: Table.new('parents'),
                                class_name: 'ParentClass',
                                name: 'parent',
                                name_field: 'name')
        field.add_search_condition(:index, sign: :eq, form_kind: 'select')
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :parent_id_eq, :select, " +
                       "list: Admin::ParentClass.all.pluck(:name, :id), selected_value: form.object.parent_id_eq)", code)
      end
  
      test "condition has select enum, search_condition_form_code should be return select component" do
        fields = []
        field = Field.new('status')
        enum = field.build_enum
        enum.add_elements(key: :ordered, value: 1)
        enum.add_elements(key: :charged, value: 2)
        enum.add_elements(key: :delivered, value: 3)
        field.add_search_condition(:index, sign: :eq, form_kind: :select)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :status_eq, :select, " +
                       "list: Admin::Product.statuses_i18n.invert, selected_value: form.object.status_eq)", code)
      end
  
      test "condition has any enum, search_condition_form_code should be return checkbox component" do
        fields = []
        field = Field.new('status')
        enum = field.build_enum
        enum.add_elements(key: :ordered, value: 1)
        enum.add_elements(key: :charged, value: 2)
        enum.add_elements(key: :delivered, value: 3)
        field.add_search_condition(:index, sign: :any, form_kind: :checkbox)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :status_any, :checkbox, " +
                       "list: Admin::Product.statuses_i18n, checked_values: form.object.status_any)", code)
      end
  
      test "condition has boolean, search_condition_form_code should be return switch component" do
        fields = []
        field = Field.new('removed', :boolean)
        field.add_search_condition(:index, sign: :eq, form_kind: :switch)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :removed_eq, :switch, include_hidden: true)", code)
      end
  
      test "condition has date, search_condition_form_code should be return text with datepicker" do
        fields = []
        field = Field.new('published_on', :date)
        field.add_search_condition(:index, sign: :gteq, form_kind: :text)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :published_on_gteq, :text, datepicker: true, " +
                       "prepend: '#{condition.sign_label}')", code)
      end
  
      test "condition has datetime, search_condition_form_code should be return text with datepicker" do
        fields = []
        field = Field.new('delivered_at', :datetime)
        field.add_search_condition(:index, sign: :lteq, form_kind: :text)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :delivered_at_lteq, :text, datepicker: true, " +
                       "prepend: '#{condition.sign_label}')", code)
      end
  
      test "condition has decorator(prepend), search_condition_form_code should be return text with prepend" do
        fields = []
        field = Field.new('price', :int)
        field.build_decorator(prepend: '$', digit: true)
        field.add_search_condition(:index, sign: :eq, form_kind: :text)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :price_eq, :text, " +
                       "prepend: '#{condition.sign_label} $')", code)
      end
  
      test "condition has decorator(append), search_condition_form_code should be return text with prepend" do
        fields = []
        field = Field.new('price', :int)
        field.build_decorator(append: 'YEN', digit: true)
        field.add_search_condition(:index, sign: :eq, form_kind: :text)
        fields << field
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        condition = resource.conditions.first
        code = writer.search_condition_form_code(condition)
        assert_equal("= render Admin::FieldsetComponent.new(form, :price_eq, :text, " +
                       "prepend: '#{condition.sign_label}', append: 'YEN')", code)
      end
  
      test "index_list_header_code should be return field code" do
        fields = []
        %w(id name category).each do |name|
          field = Field.new(name)
          field.in_index_list = true
          fields << field
        end
  
        resource = Resource.new('Product', fields)
        writer = IndexWriter.new(resource)
        list_field = resource.index_list_fields.last
        code = writer.index_list_header_code(list_field)
        assert_equal("= render Admin::SortableComponent.new(@search, :category)", code)
      end
    end
  end
end