require 'rails/generators/base'
require 'infold/writers/search_form_writer'
require 'infold/resource'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  class SearchFormGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      resource_name = name.camelize.singularize
      db_schema = DbSchema.new(File.read(Rails.root.join('db/schema.rb')))
      yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
      resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
      @writer = SearchFormWriter.new(resource)
    end

    def create_model_file
      template "search_form.rb", Rails.root.join("app/forms/admin", "#{name.underscore.singularize}_search_form.rb"), force: true
    end
  end
end