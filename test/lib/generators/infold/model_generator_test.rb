# frozen_string_literal: true
require 'test_helper'
require "generators/infold/model_generator"

module Infold
  class ModelGeneratorTest < ::Rails::Generators::TestCase
    tests ModelGenerator
    destination Rails.root.join('app/models/admin')
    # remove destination exist files
    setup :prepare_destination

    test "generates infold_model" do
      run_generator ['Product']
      assert_file Rails.root.join("app/models/admin/product.rb") do |content|
        assert_match /module Admin/, content
        assert_match /class Product < ::Product/, content
        # association
        assert_match /has_many :purchase_details, dependent: :restrict_with_error/, content
        # validates
        assert_match /validates :title, presence: true/, content
        # enum
        assert_match /enum category: { kitchen: 1, dining: 2, bedroom: 3, bathroom: 4 }, _prefix: true/, content
        # scope
        assert_match /scope :id_eq, ->\(v\) do/, content
      end
    end
  end
end