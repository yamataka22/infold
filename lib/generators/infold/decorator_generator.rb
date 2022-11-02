require 'rails/generators/base'
require 'infold/writers/decorator_writer'
require 'infold/resource'

module Infold
  class DecoratorGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      yaml = YAML.load_file(Rails.root.join("infold/#{name}.yml"))
      resource = Resource.new(name, yaml)
      @writer = DecoratorWriter.new(resource)
    end

    def create_model_file
      template "decorator.rb", Rails.root.join("infold/model", "#{name}_decorator.rb"), force: true
    end
  end
end