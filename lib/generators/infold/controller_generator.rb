require 'rails/generators/base'
require 'infold/writers/controller_writer'
require 'infold/resource'

module Infold
  class ControllerGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      yaml = YAML.load_file(Rails.root.join("infold/#{name}.yml"))
      resource = Resource.new(name, yaml)
      @writer = ControllerWriter.new(resource)
    end

    def create_model_file
      template "controller.rb", Rails.root.join("infold/model", "#{name}_controller.rb"), force: true
    end
  end
end