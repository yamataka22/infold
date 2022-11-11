require 'test_helper'
require 'infold/writers/search_form_writer'
require 'infold/table'
require 'infold/field'
require 'infold/resource'

module Infold
  class SearchFormWriterTest < ::ActiveSupport::TestCase

    test "set_conditions_code should generate set condition each field" do
      fields = []
      field = Field.new('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      fields << field

      field = Field.new('name')
      field.add_search_condition(:index, sign: :full_like, form_kind: :text)
      fields << field

      field = Field.new('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)
      fields << field

      field = Field.new('id')
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)
      fields << field

      field = Field.new('status')
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)
      fields << field

      field = Field.new('price')
      field.add_search_condition(:association_search, sign: :gteq, form_kind: :text)
      fields << field

      resource = Resource.new('Product', fields)
      writer = SearchFormWriter.new(resource, nil)
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

    test "record_search_includes_code should generate 'include belongs_to associations'" do
      fields = []
      field = Field.new('details')
      field.build_association(kind: :has_many, association_table: Table.new('details'))
      fields << field

      field = Field.new('one_parent_id')
      field.build_association(kind: :belongs_to, association_table: Table.new('one_parents'), name: 'one_parent')
      fields << field

      field = Field.new('two_parent_id')
      field.build_association(kind: :belongs_to, association_table: Table.new('two_parents'), name: 'two_parent')
      fields << field

      resource = Resource.new('Product', fields)
      writer = SearchFormWriter.new(resource, nil)
      code = writer.record_search_includes_code
      assert_match("includes(:one_parent, :two_parent)", code)
      refute_match("details", code)
    end

    test "if belongs_to association is blank, record_search_includes_code should return nil" do
      fields = []
      field = Field.new('details')
      field.build_association(kind: :has_many, association_table: Table.new('details'))
      fields << field

      resource = Resource.new('Product', fields)
      writer = SearchFormWriter.new(resource, nil)
      code = writer.record_search_includes_code
      assert_nil(code)
    end
  end
end