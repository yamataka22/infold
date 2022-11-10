require 'test_helper'
require 'infold/writers/model_writer'
require 'infold/table'
require 'infold/field'
require 'infold/resource'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    test "association_code should generate has_many, has_one, belongs_to" do
      fields = []
      field = Field.new('one_details')
      field.build_association(kind: :has_many, association_table: Table.new('one_details'))
      fields << field

      field = Field.new('tow_detail')
      field.build_association(kind: :has_one, association_table: Table.new('one_details'))
      fields << field

      field = Field.new('parent_id')
      field.build_association(kind: :belongs_to, association_table: Table.new('parents'), name: 'parent')
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.association_code
      assert_match("has_many :one_details", code)
      assert_match("has_one :tow_detail", code)
      assert_match("belongs_to :parent", code)
    end

    test "association_code should generate association with options if resource.associations defined in hash" do
      fields = []
      field = Field.new('one_details')
      field.build_association(kind: :has_many,
                              association_table: Table.new('one_details'),
                              foreign_key: 'one_detail_id',
                              dependent: 'destroy')
      fields << field

      field = Field.new('two_details')
      field.build_association(kind: :has_many,
                              association_table: Table.new('one_details'),
                              class_name: 'TwoDetail',
                              dependent: 'delete_all')
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.association_code
      assert_match("has_many :one_details, foreign_key: 'one_detail_id', dependent: :destroy", code)
      assert_match("has_many :two_details, class_name: 'TwoDetail', dependent: :delete_all", code)
    end

    test "accepts_nested_attributes_code should generate accepts_nested_attributes_for if resource.form contains associations" do
      fields = []
      field = Field.new('one_details')
      field.build_association(kind: :has_many, association_table: Table.new('one_details'))
      field.build_form_element(form_kind: :associations)
      fields << field

      field = Field.new('tow_details')
      field.build_association(kind: :has_many, association_table: Table.new('one_details'))
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.accepts_nested_attributes_code
      assert_match("accepts_nested_attributes_for :one_details", code)
      refute_match("accepts_nested_attributes_for :two_details", code)
    end

    test "datetime_field_code should generate except timestamp filed" do
      fields = []
      fields << Field.new('delivery_at', 'datetime')
      fields << Field.new('created_at', 'datetime')
      fields << Field.new('updated_at', 'datetime')

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.datetime_field_code
      assert_match("datetime_field :delivery_at", code)
      refute_match("datetime_field :created_at", code)
      refute_match("datetime_field :updated_at", code)
    end

    test "active_storage_attachment_code should generate active_storage field" do
      fields = []
      field = Field.new('image')
      field.build_active_storage(kind: :image)
      fields << field

      field = Field.new('pdf')
      field.build_active_storage(kind: :file)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.active_storage_attachment_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        has_one_attached :image
        attr_accessor :remove_image
        before_validation { self.image = nil if remove_image.to_s == '1' }
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("has_one_attached :pdf", code)
    end

    test "active_storage_attachment_code should generate active_storage field with thumb" do
      fields = []
      field = Field.new('image')
      active_storage = field.build_active_storage(kind: :image)
      active_storage.build_thumb(kind: :fit, width: 100, height: 200)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.active_storage_attachment_code
      expect_code = <<-RUBY.gsub(/^\s+/, '')
        has_one_attached :image do |attachable|
          attachable.variant :thumb, resize_to_fit: [100, 200]
        end
        attr_accessor :remove_image
      RUBY
      assert_match(expect_code, code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "validation_code should generate presence validates" do
      fields = []
      field = Field.new('stock')
      field.add_validation(:presence)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.validation_code
      assert_equal("validates :stock, presence: true", code.gsub(/^\s+|\n/, ''))
    end

    test "validation_code should generate multiple validates" do
      fields = []
      field = Field.new('stock')
      field.add_validation(:presence)
      fields << field

      field = Field.new('name')
      field.add_validation(:presence)
      field.add_validation(:uniqueness)
      fields << field

      field = Field.new('price')
      field.add_validation(:uniqueness)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.validation_code
      assert_match("validates :stock, presence: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("validates :name, presence: true, uniqueness: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("validates :price, allow_blank: true, uniqueness: true", code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "validation_code should generate validates include options" do
      fields = []
      field = Field.new('price')
      field.add_validation(:presence)
      field.add_validation(:numericality, { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 })
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.validation_code
      assert_match("validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }",
                   code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "enum_code should generate enum" do
      fields = []
      field = Field.new('status')
      enum = field.build_enum
      enum.add_elements(key: :ordered, value: 1)
      enum.add_elements(key: :charged, value: 2)
      fields << field

      field = Field.new('category')
      enum = field.build_enum
      enum.add_elements(key: :kitchen, value: 1)
      enum.add_elements(key: :living, value: 2)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.enum_code
      assert_match("enum status: { ordered: 1, charged: 2 }, _prefix: true", code.gsub(/^\s+|\[TAB\]/, ''))
      assert_match("enum category: { kitchen: 1, living: 2 }, _prefix: true", code.gsub(/^\s+|\[TAB\]/, ''))
    end

    test "scope_code should generate scope (only index_conditions, except datetime)" do
      fields = []
      field = Field.new('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      fields << field

      field = Field.new('name')
      field.add_search_condition(:index, sign: :full_like, form_kind: :text)
      fields << field

      field = Field.new('price')
      field.add_search_condition(:index, sign: :gteq, form_kind: :text)
      fields << field

      field = Field.new('company_id')
      field.add_search_condition(:index, sign: :eq, form_kind: :association)
      fields << field

      field = Field.new('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)
      fields << field

      field = Field.new('address')
      field.add_search_condition(:index, sign: :start_with, form_kind: :text)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.scope_code
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
      assert_match('where(company_id: v) if v.present?', code)
      assert_match('where(arel_table[:price].gteq(v)) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:address].matches("#{v}%")) if v.present?', code)
    end

    test "scope_code should generate scope (index_conditions and association_conditions, except datetime)" do
      fields = []
      field = Field.new('id')
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      field.add_search_condition(:association_search, sign: :eq, form_kind: :text)
      fields << field

      field = Field.new('company_id')
      field.add_search_condition(:index, sign: :eq, form_kind: :association)
      fields << field

      field = Field.new('status')
      field.add_search_condition(:index, sign: :any, form_kind: :checkbox)
      fields << field

      field = Field.new('name')
      field.add_search_condition(:association_search, sign: :full_like, form_kind: :text)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
      code = writer.scope_code
      assert_equal(4, code.scan('scope').size)
      assert_match('where(id: v) if v.present?', code)
      assert_match('where(status: v) if v.present?', code)
      assert_match('where(arel_table[:name].matches("%#{v}%")) if v.present?', code)
    end

    test "scope_code should generate scope (about datetime)" do
      fields = []
      field = Field.new('delivery_at', :datetime)
      field.add_search_condition(:index, sign: :eq, form_kind: :text)
      field.add_search_condition(:index, sign: :lteq, form_kind: :text)
      fields << field

      resource = Resource.new('Product', fields)
      writer = ModelWriter.new(resource)
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