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
      yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
      @resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
    end

    def create_model_file
      @writer = ModelWriter.new(@resource)
      template "model.rb", Rails.root.join("app/models/admin", "#{name.underscore.singularize}.rb"), force: true
    end

    def create_association_model_file
      @resource.associations&.
        select { |as| !as.belongs_to? && as.field_group.has_association_model? }&.each do |association|
        @writer = ModelWriter.new(association)
        template "model.rb", Rails.root.join("app/models/admin", "#{association.model_name(:snake)}.rb"), force: true
      end
    end
  end
end