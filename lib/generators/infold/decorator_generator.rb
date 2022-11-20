require 'rails/generators/base'
require 'infold/writers/decorator_writer'
require 'infold/resource'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  class DecoratorGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      resource_name = name.camelize.singularize
      db_schema = DbSchema.new(File.read(Rails.root.join('db/schema.rb')))
      yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
      resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
      @writer = DecoratorWriter.new(resource)
    end

    def create_model_file
      template "decorator.rb", Rails.root.join("app/decorators/admin/#{name.underscore.singularize}_decorator.rb"), force: true
    end
  end
end