# frozen_string_literal: true
require 'test_helper'
require "generators/infold/resource_generator"

module Infold
  class ResourceGeneratorTest < ::Rails::Generators::TestCase
    tests ResourceGenerator
    destination Rails.root.join('config/infold')
    # remove destination exist files
    # setup :prepare_destination

    test "generates infold_resource" do
      run_generator ['Product']
      assert_file Rails.root.join("config/infold/product.yml") do |content|
        assert_match /title: PRODUCTS/, content
        assert_match /- id:\n\s+sign: eq/, content
      end
    end
  end
end