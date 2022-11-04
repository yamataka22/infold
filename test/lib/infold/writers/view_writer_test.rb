require 'test_helper'
require 'infold/writers/view_writer'
require 'infold/resource'
require 'infold/db_schema'

module Infold
  class ViewWriterTest < ::ActiveSupport::TestCase

    setup do
      @resource = Resource.new("product", {})
    end

    test "condition has association_search, search_condition_form_code should be return FieldsetComponent(:association)" do
      yaml = <<-"YAML"
        model:
          association:
            staff:
              kind: belongs_to
              name_field: name
        app:
          index:
            conditions:
              - staff_id:
                  sign: eq
                  form_kind: association_search
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :staff_id_eq, :association, association: :staffs, " +
                  "search_path: admin_staffs_path, name_field: :staff_name)", code)
    end

    test "condition has select association, search_condition_form_code should be return select component" do
      yaml = <<-"YAML"
        model:
          association:
            staff:
              kind: belongs_to
              name_field: name
        app:
          index:
            conditions:
              - staff_id:
                  sign: eq
                  form_kind: select
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :staff_id_eq, :select, " +
                     "list: Admin::Staff.all.pluck(:name, :id), selected_value: form.object.staff_id_eq)", code)
    end

    test "condition has select enum, search_condition_form_code should be return select component" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
        app:
          index:
            conditions:
              - status:
                  sign: eq
                  form_kind: select
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :status_eq, :select, " +
                     "list: Admin::Product.statuses_i18n.invert, selected_value: form.object.status_eq)", code)
    end

    test "condition has any enum, search_condition_form_code should be return checkbox component" do
      yaml = <<-"YAML"
        model:
          enum:
            status:
              ordered: 1
              charged: 2
              delivered: 3
        app:
          index:
            conditions:
              - status:
                  sign: any
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :status_any, :checkbox, " +
                     "list: Admin::Product.statuses_i18n, checked_values: form.object.status_any)", code)
    end

    test "condition has boolean, search_condition_form_code should be return switch component" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - removed:
                  form_kind: switch
      YAML
      resource = Resource.new('product', YAML.load(yaml))
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :removed_eq, :switch, include_hidden: false)", code)
    end

    test "condition has date, search_condition_form_code should be return text with datepicker" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - published_on:
                  sign: gteq
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.date "published_on"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :published_on_gteq, :text, datepicker: true, " +
                     "prepend: '#{writer.sign_label('gteq')}')", code)
    end

    test "condition has datetime, search_condition_form_code should be return text with datepicker" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - delivered_at:
                  sign: lteq
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.string "name"
          t.datetime "delivered_at"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :delivered_at_lteq, :text, datepicker: true, " +
                     "prepend: '#{writer.sign_label('lteq')}')", code)
    end

    test "condition has decorator(prepend), search_condition_form_code should be return text with prepend" do
      yaml = <<-"YAML"
        model:
          decorate:
            price:
              prepend: $
              digit: true
        app:
          index:
            conditions:
              - price:
                  sign: eq
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.integer "price"
          t.datetime "delivered_at"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :price_eq, :text, " +
                     "prepend: '#{writer.sign_label('eq')} $')", code)
    end

    test "condition has decorator(append), search_condition_form_code should be return text with prepend" do
      yaml = <<-"YAML"
        model:
          decorate:
            price:
              append: YEN
              digit: true
        app:
          index:
            conditions:
              - price:
                  sign: eq
      YAML
      db_schema_content = <<-"RUBY"
        create_table "products" do |t|
          t.integer "price"
          t.datetime "delivered_at"
        end
      RUBY
      db_schema = DbSchema.new(db_schema_content)
      resource = Resource.new('product', YAML.load(yaml), db_schema)
      condition = resource.index_conditions.first
      writer = ViewWriter.new(resource)
      code = writer.search_condition_form_code(condition)
      assert_equal("= render Admin::FieldsetComponent.new(form, :price_eq, :text, " +
                     "prepend: '#{writer.sign_label('eq')}', append: 'YEN')", code)
    end
  end
end