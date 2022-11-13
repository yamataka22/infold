# frozen_string_literal: true
require 'test_helper'
require "generators/infold/decorator_generator"

module Infold
  class DecoratorGeneratorTest < ::Rails::Generators::TestCase
    tests DecoratorGenerator
    destination Rails.root.join('app/decorators/admin')
    # remove destination exist files
    setup :prepare_destination

    test "generates infold:decorator" do
      run_generator ['Product']
      assert_file Rails.root.join("app/decorators/admin/product_decorator.rb") do |content|
        assert_match /module Admin/, content
        assert_match /module ProductDecorator/, content
        assert_match /def price_display\n\s+\"\$\#{price.to_formatted_s\(:delimited\)}\" if price.present\?/, content
      end
    end
  end
end