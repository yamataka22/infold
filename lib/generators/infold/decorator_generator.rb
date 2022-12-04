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
      db_schema_file = Rails.root.join('db/schema.rb')
      db_schema = DbSchema.new(File.exist?(db_schema_file) ? File.read(db_schema_file) : nil)
      yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
      @resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
    end

    def create_model_file
      @writer = DecoratorWriter.new(@resource)
      template "decorator.rb", Rails.root.join("app/decorators/admin/#{name.underscore.singularize}_decorator.rb"), force: true
    end

    def create_association_model_file
      @resource.associations&.
        select { |as| !as.belongs_to? && as.field_group.has_association_model? }&.each do |association|
        @writer = DecoratorWriter.new(association)
        template "decorator.rb", Rails.root.join("app/decorators/admin/#{association.model_name(:snake)}_decorator.rb"), force: true
      end
    end
  end
end