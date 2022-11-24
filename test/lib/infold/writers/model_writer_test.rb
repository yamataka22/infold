require 'test_helper'
require 'infold/writers/model_writer'
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

    test "it should generate has_many, has_one and belongs_to association_code" do
      field = @field_group.add_field('one_details')
      field.build_association(kind: :has_many, table: Table.new('one_details'))
      field = @field_group.add_field('tow_detail')
      field.build_association(kind: :has_one, table: Table.new('one_details'))
      field = @field_group.add_field('parent_id')
      field.build_association(kind: :belongs_to, table: Table.new('parents'), name: 'parent')

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.association_code
      assert_match("has_many :one_details", code)
      assert_match("has_one :tow_detail", code)
      assert_match("belongs_to :parent", code)
    end

    test "it should generate association_code with options" do
      field = @field_group.add_field('one_details')
      field.build_association(kind: :has_many,
                              name: 'one_details',
                              table: Table.new('one_details'),
                              foreign_key: 'one_detail_id',
                              dependent: 'destroy')
      field = @field_group.add_field('two_details')
      field.build_association(kind: :has_many,
                              name: 'two_details',
                              table: Table.new('two_details'),
                              class_name: 'TwoDetail',
                              dependent: 'delete_all')
      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.association_code
      assert_match("has_many :one_details, foreign_key: 'one_detail_id', dependent: :destroy", code)
      assert_match("has_many :two_details, class_name: 'TwoDetail', dependent: :delete_all", code)
    end

    test "it should generate accepts_nested_attributes_for" do
      field = @field_group.add_field('one_details')
      field.build_association(kind: :has_many, table: Table.new('one_details'))
      field.build_form_element(form_kind: :associations)
      field = @field_group.add_field('tow_details')
      field.build_association(kind: :has_many, table: Table.new('one_details'))

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.accepts_nested_attributes_code
      assert_match("accepts_nested_attributes_for :one_details", code)
      refute_match("accepts_nested_attributes_for :two_details", code)
    end

    test "it should generate datetime_field_code except timestamp filed" do
      @field_group.add_field('delivery_at', 'datetime')
      @field_group.add_field('created_at', 'datetime')
      @field_group.add_field('updated_at', 'datetime')

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.datetime_field_code
      assert_match("datetime_field :delivery_at", code)
      refute_match("datetime_field :created_at", code)
      refute_match("datetime_field :updated_at", code)
    end

    test "it should generate active_storage_attachment_code" do
      field = @field_group.add_field('photo')
      field.build_active_storage(kind: :image)
      field = @field_group.add_field('pdf')
      field.build_active_storage(kind: :file)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.active_storage_attachment_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        has_one_attached :photo
        attr_accessor :remove_photo
        before_validation { self.photo = nil if remove_photo.to_s == '1' }
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("has_one_attached :pdf", code)
    end

    test "it should generate active_storage_attachment_code with thumb" do
      field = @field_group.add_field('image')
      active_storage = field.build_active_storage(kind: :image)
      active_storage.build_thumb(kind: :fit, width: 100, height: 200)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.active_storage_attachment_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        has_one_attached :image do |attachable|
          attachable.variant :thumb, resize_to_fit: [100, 200]
        end
        attr_accessor :remove_image
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should generate presence validation_code" do
      field = @field_group.add_field('stock')
      field.add_validation(:presence)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.validation_code
      assert_equal("validates :stock, presence: true", code.gsub(/^\s+|\n/, ''))
    end

    test "it should generate multiple validation_code" do
      field = @field_group.add_field('stock')
      field.add_validation(:presence)
      field = @field_group.add_field('name')
      field.add_validation(:presence)
      field.add_validation(:uniqueness)
      field = @field_group.add_field('price')
      field.add_validation(:uniqueness)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.validation_code
      assert_match("validates :stock, presence: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("validates :name, presence: true, uniqueness: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("validates :price, allow_blank: true, uniqueness: true", code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should generate validation_code include options" do
      field = @field_group.add_field('price')
      field.add_validation(:presence)
      field.add_validation(:numericality, { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 })

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.validation_code
      assert_match("validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }",
                   code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should generate enum_code" do
      field = @field_group.add_field('status')
      enum = field.build_enum
      enum.add_elements(key: :ordered, value: 1)
      enum.add_elements(key: :charged, value: 2)

      field = @field_group.add_field('category')
      enum = field.build_enum
      enum.add_elements(key: :kitchen, value: 1)
      enum.add_elements(key: :living, value: 2)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.enum_code
      assert_match("enum status: { ordered: 1, charged: 2 }, _prefix: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("enum category: { kitchen: 1, living: 2 }, _prefix: true", code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "it should generate scope_code (only index_conditions, except datetime)" do
      field = @field_group.add_field('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)

      field = @field_group.add_field('name')
      field.add_search_condition(:index, sign: :full_like, form_kind: :text)

      field = @field_group.add_field('price')
      field.add_search_condition(:index, sign: :gteq, form_kind: :text)

      field = @field_group.add_field('company_id')
      field.add_search_condition(:index, sign: :eq, form_kind: :association)

      field = @field_group.add_field('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)

      field = @field_group.add_field('address')
      field.add_search_condition(:index, sign: :start_with, form_kind: :text)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.scope_code
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
      assert_match('where(company_id: v) if v.present?', code)
      assert_match('where(arel_table[:price].gteq(v)) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:address].matches("#{v}%")) if v.present?', code)
    end

    test "it should generate scope_code (index_conditions and association_conditions, except datetime)" do
      field = @field_group.add_field('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)

      field = @field_group.add_field('company_id')
      field.add_search_condition(:index, sign: :eq, form_kind: :association)

      field = @field_group.add_field('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)

      field = @field_group.add_field('name')
      field.add_search_condition(:association_search, sign: :full_like, form_kind: :text)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.scope_code
      assert_equal(4, code.scan('scope').size)
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
    end

    test "it should generate scope_code (about datetime)" do
      field = @field_group.add_field('delivery_at', :datetime)
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      field.add_search_condition(:index, sign: :lteq, form_kind: :text)

      @resource.field_group = @field_group
      writer = ModelWriter.new(@resource)
      code = writer.scope_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        scope :delivery_at_eq, ->(v) do
          return if v.blank?
          begin
            where(delivery_at: v.to_date.all_day)
          rescue
            where(arel_table[:delivery_at].eq(v))
          end
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))

      expect_code = <<-RUBY.gsub(/^\s+/, '')
        scope :delivery_at_lteq, ->(v) do
          return if v.blank?
          begin
            v = v.to_date.next_day
          rescue
          end
          where(arel_table[:delivery_at].lteq(v))
        end
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end
  end
end