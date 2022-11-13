# frozen_string_literal: true
require 'test_helper'
require "generators/infold/search_form_generator"

module Infold
  class DecoratorGeneratorTest < ::Rails::Generators::TestCase
    tests SearchFormGenerator
    destination Rails.root.join('app/forms/admin')
    # remove destination exist files
    setup :prepare_destination

    test "generates infold:search_form" do
      run_generator ['products']
      assert_file Rails.root.join("app/forms/admin/product_search_form.rb") do |content|
        assert_match /module Admin/, content
        assert_match /class ProductSearchForm < SearchFormBase/, content
        assert_match /set_condition :id_eq/, content
        assert_match /records = Product.distinct/, content
      end
    end
  end
end