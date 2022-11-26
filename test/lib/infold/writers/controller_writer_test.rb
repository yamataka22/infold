require 'test_helper'
require 'infold/writers/controller_writer'
require 'infold/table'
require 'infold/field_group'
require 'infold/field'
require 'infold/resource'

module Infold
  class ControllerWriterTest < ::ActiveSupport::TestCase

    def setup
      @field_group = FieldGroup.new
      @resource = Resource.new('Product')
    end

    test "it should generate build_new_association_code" do
      field = @field_group.add_field('one_details')
      field.build_association(kind: :has_many, table: Table.new('one_details'))
      field.build_form_element

      field = @field_group.add_field('two_detail')
      field.build_association(kind: :has_one, table: Table.new('two_details'))
      field.build_form_element

      @resource.field_group = @field_group
      writer = ControllerWriter.new(@resource)
      code = writer.association_build_code
      assert_match(/@product.one_details.build$/, code.gsub(/^\s+/, ''))
      assert_match(/@product.build_two_detail$/, code.gsub(/^\s+/, ''))
    end

    test "build_new_association_code(if_blank: true) should generate association build code append 'if blank'" do
      field = @field_group.add_field('details')
      field.build_association(kind: :has_many, table: Table.new('details'))
      field.build_form_element

      @resource.field_group = @field_group
      writer = ControllerWriter.new(@resource)
      code = writer.association_build_code(if_blank: true)
      assert_match("@product.details.build if @product.details.blank? && @product.errors[:details].any?", code.gsub(/^\s+/, ''))
    end

    test "search_params_code should generate search conditions params" do
      field = @field_group.add_field('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)

      field = @field_group.add_field('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)

      field = @field_group.add_field('price')
      field.add_search_condition(:association_search, sign: :gteq, form_kind: :text)

      @resource.field_group = @field_group
      writer = ControllerWriter.new(@resource)
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
      field = @field_group.add_field('name')
      field.build_form_element(seq: 0)

      field = @field_group.add_field('price')
      field.build_form_element(form_kind: :number, seq: 1)

      field = @field_group.add_field('published_at', :datetime)
      field.build_form_element(seq: 2)

      field = @field_group.add_field('image')
      field.build_active_storage(kind: :image)
      field.build_form_element(form_kind: :file, seq: 3)

      field = @field_group.add_field('one_details')
      association_field_group = FieldGroup.new
      field_title = association_field_group.add_field('title')
      field_stock = association_field_group.add_field('stock')
      field.build_association(kind: :has_many, table: Table.new('one_details'), field_group: association_field_group)
      form_element = field.build_form_element(form_kind: :association, seq: 4)
      form_element.add_association_fields(field_title, seq: 0)
      form_element.add_association_fields(field_stock, form_kind: :number, seq: 1)

      field = @field_group.add_field('two_details')
      association_field_group = FieldGroup.new
      field_birthday = association_field_group.add_field('birthday', :date)
      field.build_association(kind: :has_many, table: Table.new('two_details'), field_group: association_field_group)
      form_element = field.build_form_element(form_kind: :association, seq: 5)
      form_element.add_association_fields(field_birthday, seq: 0)

      field = @field_group.add_field('three_detail')
      association_field_group = FieldGroup.new
      field_removed_at = association_field_group.add_field('removed_at', :datetime)
      field_pdf = association_field_group.add_field('pdf')
      field_pdf.build_active_storage(kind: :file)
      field.build_association(kind: :has_one, table: Table.new('three_details'), field_group: association_field_group)
      form_element = field.build_form_element(form_kind: :association, seq: 6)
      form_element.add_association_fields(field_pdf, seq: 0)
      form_element.add_association_fields(field_removed_at, seq: 1)

      @resource.field_group = @field_group
      writer = ControllerWriter.new(@resource)
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
            :id,
            :_destroy,
            :title,
            :stock
          ],
          two_details_attributes: [
            :id,
            :_destroy,
            :birthday
          ],
          three_detail_attributes: [
            :id,
            :_destroy,
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