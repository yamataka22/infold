require 'test_helper'
require 'infold/writers/search_form_writer'
require 'infold/table'
require 'infold/field_group'
require 'infold/field'
require 'infold/resource'

module Infold
  class SearchFormWriterTest < ::ActiveSupport::TestCase

    def setup
      @field_group = FieldGroup.new
      @resource = Resource.new('Product')
    end
    
    test "it should generate set_conditions_code each fields" do
      field = @field_group.add_field('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)

      field = @field_group.add_field('name')
      field.add_search_condition(:index, sign: :full_like, form_kind: :text)

      field = @field_group.add_field('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)

      field = @field_group.add_field('id')
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)

      field = @field_group.add_field('status')
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)

      field = @field_group.add_field('price')
      field.add_search_condition(:association_search, sign: :gteq, form_kind: :text)

      @resource.field_group = @field_group
      writer = SearchFormWriter.new(@resource)
      code = writer.set_conditions_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        set_condition :id_eq,
          :name_full_like,
          :status_any,
          :status_eq,
          :price_gteq
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should generate record_search_includes_code" do
      field = @field_group.add_field('details')
      field.build_association(kind: :has_many, table: Table.new('details'))

      field = @field_group.add_field('one_parent_id')
      field.build_association(kind: :belongs_to, table: Table.new('one_parents'), name: 'one_parent')

      field = @field_group.add_field('two_parent_id')
      field.build_association(kind: :belongs_to, table: Table.new('two_parents'), name: 'two_parent')

      @resource.field_group = @field_group
      writer = SearchFormWriter.new(@resource)
      code = writer.record_search_includes_code
      assert_match("includes(:one_parent, :two_parent)", code)
      refute_match("details", code)
    end

    test "if belongs_to association is blank, it should return nil" do
      field = @field_group.add_field('details')
      field.build_association(kind: :has_many, table: Table.new('details'))

      @resource.field_group = @field_group
      writer = SearchFormWriter.new(@resource)
      code = writer.record_search_includes_code
      assert_nil(code)
    end
  end
end