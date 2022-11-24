# frozen_string_literal: true
require 'test_helper'
require "generators/infold/views/form_generator"

module Infold
  module Views
    class FormGeneratorTest < ::Rails::Generators::TestCase
      tests FormGenerator
      destination Rails.root.join('app/views/admin/purchases')
      # remove destination exist files
      # setup :prepare_destination

      test "generates infold:views:form" do
        run_generator ['purchases']
        assert_file Rails.root.join("app/views/admin/purchases/new.html+turbo_frame.haml") do |content|
          assert_match "= form_with model: @purchase do |form|", content
        end

        assert_file Rails.root.join("app/views/admin/purchases/edit.html+turbo_frame.haml") do |content|
          assert_match "= form_with model: @purchase do |form|", content
        end

        assert_file Rails.root.join("app/views/admin/purchases/_form.html.haml") do |content|
          assert_match "= render Admin::FieldsetComponent.new(form, :customer_id, :association_search, " +
                         "required: true, association_name: :customer, " +
                         "search_path: admin_customers_path(name_field: :name), name_field: :customer_name)", content
        end

        assert_file Rails.root.join("app/views/admin/purchases/_form_purchase_detail.html.haml") do |content|
          assert_match "= render Admin::FieldsetComponent.new(form, :product_id, :association_search, " +
                         "required: true, no_label: true, association_name: :product, " +
                         "search_path: admin_products_path(name_field: :title), " +
                         "name_field: :product_title)", content
        end
      end
    end
  end
end