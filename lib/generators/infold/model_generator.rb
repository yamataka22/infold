require 'rails/generators/base'
require 'infold/writers/model_writer'
require 'infold/resource'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      resource_name = name.camelize.singularize
      db_schema = DbSchema.new(File.read(Rails.root.join('db/schema.rb')))
      yaml = YAML.load_file(Rails.root.join("infold/#{resource_name.underscore}.yml"))
      yaml_reader = YamlReader.new(resource_name, yaml, db_schema)
      resource = Resource.new(resource_name, yaml_reader.fields)
      @writer = ModelWriter.new(resource)
    end

    def create_model_file
      template "model.rb", Rails.root.join("infold", "#{name.underscore.singularize}_model.rb"), force: true
    end
  end
end