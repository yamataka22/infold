# frozen_string_literal: true
require 'test_helper'
require "generators/infold/views/index_generator"

module Infold
  module Views
    class IndexGeneratorTest < ::Rails::Generators::TestCase
      tests IndexGenerator
      destination Rails.root.join('app/views/admin/products')
      # remove destination exist files
      setup :prepare_destination

      test "generates infold:views:index" do
        run_generator ['products']
        assert_file Rails.root.join("app/views/admin/products/index.html.haml") do |content|
          assert_match "= form_with model: @search, url: admin_products_path, method: :get, scope: 'search'", content
          assert_match "= render Admin::FieldsetComponent.new(form, :id_eq, :text, placeholder: '=')", content
          assert_match "%th= render Admin::SortableComponent.new(@search, :id)", content
        end

        assert_file Rails.root.join("app/views/admin/products/_index_row.html.haml") do |content|
          assert_match "%tr{ id: dom_id(product) }", content
          assert_match "= link_to admin_product_path(product), class: 'd-block', data: { turbo_frame: 'modal_main' } do", content
          assert_match "%td= product.id", content
        end
      end
    end
  end
end