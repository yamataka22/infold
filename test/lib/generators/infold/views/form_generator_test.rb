# frozen_string_literal: true
require 'test_helper'
require "generators/infold/views/form_generator"

module Infold
  module Views
    class FormGeneratorTest < ::Rails::Generators::TestCase
      tests FormGenerator
      destination Rails.root.join('app/views/admin/products')
      # remove destination exist files
      # setup :prepare_destination

      test "generates infold:views:form" do
        run_generator ['products']
        assert_file Rails.root.join("app/views/admin/products/new.html+turbo_frame.haml") do |content|
          assert_match "= form_with model: @product do |form|", content
        end

        assert_file Rails.root.join("app/views/admin/products/edit.html+turbo_frame.haml") do |content|
          assert_match "= form_with model: @product do |form|", content
        end

        assert_file Rails.root.join("app/views/admin/products/_form.html.haml") do |content|
          assert_match "= render Admin::FieldsetComponent.new(form, :name, :text)", content
        end
      end
    end
  end
end