# frozen_string_literal: true
require 'test_helper'
require "generators/infold/model_generator"

class ModelGeneratorTest < ::Rails::Generators::TestCase
  tests Infold::ModelGenerator
  destination Rails.root.join('app/models/admin')
  # remove destination exist files
  setup :prepare_destination

  test "generates infold_model" do
    run_generator ['Product']
    assert_file Rails.root.join("app/models/admin/product.rb") do |content|
      assert_match /module Admin/, content
      assert_match /class Product/, content
    end
  end
end