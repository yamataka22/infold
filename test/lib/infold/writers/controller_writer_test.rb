require 'test_helper'
require 'infold/writers/controller_writer'
require 'infold/table'
require 'infold/field'
require 'infold/resource'

module Infold
  class ControllerWriterTest < ::ActiveSupport::TestCase

    test "build_new_association_code should generate association build code" do
      fields = []
      field = Field.new('one_details')
      field.build_association(kind: :has_many, association_table: Table.new('one_details'))
      field.build_form_element
      fields << field

      field = Field.new('two_detail')
      field.build_association(kind: :has_one, association_table: Table.new('two_details'))
      field.build_form_element
      fields << field

      resource = Resource.new('Product', fields)
      writer = ControllerWriter.new(resource)
      code = writer.association_build_code
      assert_match(/@product.one_details.build$/, code.gsub(/^\s+/, ''))
      assert_match(/@product.build_two_detail$/, code.gsub(/^\s+/, ''))
    end

    test "build_new_association_code(if_blank: true) should generate association build code append 'if blank'" do
      fields = []
      field = Field.new('details')
      field.build_association(kind: :has_many, association_table: Table.new('details'))
      field.build_form_element
      fields << field

      resource = Resource.new('Product', fields)
      writer = ControllerWriter.new(resource)
      code = writer.association_build_code(if_blank: true)
      assert_match("@product.details.build if @product.details.blank?", code.gsub(/^\s+/, ''))
    end

    test "search_params_code should generate search conditions params" do
      fields = []
      field = Field.new('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)
      fields << field

      field = Field.new('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)
      fields << field

      field = Field.new('price')
      field.add_search_condition(:association_search, sign: :gteq, form_kind: :text)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ControllerWriter.new(resource)
      code = writer.search_params_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        params[:search]&.permit(
          :id_eq,
          :price_gteq,
          :sort_field,
          :sort_kind,
          status_any: []
        )
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, '') + "\n")
    end

    test "post_params_code should generate post params" do
      fields = []

      field = Field.new('name')
      field.build_form_element
      fields << field

      field = Field.new('price')
      field.build_form_element(form_kind: :number)
      fields << field

      field = Field.new('published_at', :datetime)
      field.build_form_element
      fields << field

      field = Field.new('image')
      field.build_active_storage(kind: :image)
      field.build_form_element(form_kind: :file)
      fields << field

      field = Field.new('one_details')
      field.build_association(kind: :has_many, association_table: Table.new('one_details'))
      form_element = field.build_form_element(form_kind: :association)
      form_element.add_association_fields(Field.new('title'))
      form_element.add_association_fields(Field.new('stock'), form_kind: :number)
      fields << field

      field = Field.new('two_details')
      field.build_association(kind: :has_many, association_table: Table.new('two_details'))
      form_element = field.build_form_element(form_kind: :association)
      form_element.add_association_fields(Field.new('birthday', :date))
      fields << field

      field = Field.new('three_detail')
      field.build_association(kind: :has_one, association_table: Table.new('three_details'))
      form_element = field.build_form_element(form_kind: :association)
      association_field = Field.new('pdf')
      association_field.build_active_storage(kind: :file)
      form_element.add_association_fields(association_field)
      form_element.add_association_fields(Field.new('removed_at', :datetime))
      fields << field

      resource = Resource.new('Product', fields)
      writer = ControllerWriter.new(resource)
      code = writer.post_params_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        params.require(:admin_product).permit(
          :name,
          :price,
          :published_at_date,
          :published_at_time,
          :image,
          :remove_image,
          one_details_attributes: [
            :title,
            :stock
          ],
          two_details_attributes: [
            :birthday
          ],
          three_detail_attributes: [
            :pdf,
            :remove_pdf,
            :removed_at_date,
            :removed_at_time
          ]
        )
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, '') + "\n")
    end
  end
end