# frozen_string_literal: true

require "generators/infold/resource_generator"

class ResourceGeneratorTest < ::Rails::Generators::TestCase
  tests Infold::ResourceGenerator
  destination Rails.root.join('infold')
  setup :prepare_destination

  test "generates infold_resource" do
    run_generator ['product']
    assert_file Rails.root.join("infold/product.yml") do |content|
      assert_match /title: Product/, content
      assert_match /- id: eq/, content
    end
  end
end