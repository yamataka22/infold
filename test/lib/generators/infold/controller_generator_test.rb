# frozen_string_literal: true
require 'test_helper'
require "generators/infold/controller_generator"

module Infold
  class ControllerGeneratorTest < ::Rails::Generators::TestCase
    tests ControllerGenerator
    destination Rails.root.join('app/controllers/admin')
    # remove destination exist files
    setup :prepare_destination

    test "generates infold:controller" do
      run_generator ['products']
      assert_file Rails.root.join("app/controllers/admin/products_controller.rb") do |content|
        assert_match /module Admin/, content
        assert_match /class ProductsController < BaseController/, content
        # title
        assert_match /before_action { @page_title = /, content
        # index
        assert_match /def index\n\s+@search = ProductSearchForm.new\(search_params\)/, content
        # show
        assert_match /def show\n\s+@product = Product.find\(params\[:id\]\)/, content
        # new
        assert_match /def new\n\s+@product = Product.new/, content
        # create
        assert_match /def create\n\s+@product = Product.new/, content
        # edit
        assert_match /def edit\n\s+@product = Product.find\(params\[:id\]\)/, content
        # update
        assert_match /def update\n\s+@product = Product.find\(params\[:id\]\)/, content
        # destroy
        assert_match /def destroy\n\s+@product = Product.find\(params\[:id\]\)/, content
        # search_params
        assert_match /def search_params\n\s+params\[:search\]&.permit\(/, content
        # post_params
        assert_match /def post_params\n\s+params.require\(:admin_product\).permit\(/, content
      end
    end
  end
end