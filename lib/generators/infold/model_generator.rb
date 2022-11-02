require 'rails/generators/base'
require 'infold/writers/model_writer'
require 'infold/resource'

module Infold
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      yaml = YAML.load_file(Rails.root.join("infold/#{name}.yml"))
      resource = Resource.new(name, yaml)
      @writer = ModelWriter.new(resource)
    end

    def create_model_file
      template "model.rb", Rails.root.join("infold/model", "#{name}_model.rb"), force: true
    end
  end
end