# frozen_string_literal: true
require 'test_helper'
require "generators/infold/views/show_generator"

module Infold
  module Views
    class IndexGeneratorTest < ::Rails::Generators::TestCase
      tests ShowGenerator
      destination Rails.root.join('app/views/admin/products')
      # remove destination exist files
      setup :prepare_destination

      test "generates infold:views:show" do
        run_generator ['products']
        assert_file Rails.root.join("app/views/admin/products/show.html+turbo_frame.haml") do |content|
          assert_match "= turbo_frame_tag(admin_remote_modal_id) do", content
          assert_match "= render 'show_wrapper', modal: modal, product: @product", content
        end

        assert_file Rails.root.join("app/views/admin/products/_show_wrapper.html.haml") do |content|
          assert_match '= "Product / ##{product.id}"', content
          assert_match "= render 'show_content', product: product", content
          expect_code = "= link_to t('infold.operation.edit'), edit_admin_product_path(product), " +
            "class: 'btn btn-primary', data: { turbo_frame: \"modal_main\" }"
          assert_match expect_code.gsub(/\s/, ''), content.gsub(/\n|\s/, '')
          expect_code = "= link_to t('infold.operation.delete'), admin_product_path(product), " +
            "class: 'btn btn-danger ms-1', data: { turbo_confirm: t('infold.operation.confirm', " +
            "submit: t('infold.operation.delete')), turbo_method: :delete, turbo_frame: \"_top\" }"
          assert_match expect_code.gsub(/\s/, ''), content.gsub(/\n|\s/, '')
        end

        assert_file Rails.root.join("app/views/admin/products/_show_content.html.haml") do |content|
          assert_match '.list-group', content
          assert_match '.fw-bold= product.class.human_attribute_name(:name)', content
          assert_match '= product.description', content
        end
      end
    end
  end
end