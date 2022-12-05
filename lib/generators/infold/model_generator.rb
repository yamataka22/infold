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
      db_schema_file = Rails.root.join('db/schema.rb')
      db_schema = DbSchema.new(File.exist?(db_schema_file) ? File.read(db_schema_file) : nil)
      yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
      @resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
    end

    def create_model_file
      @writer = ModelWriter.new(@resource)
      template "model.rb", Rails.root.join("app/models/admin", "#{name.underscore.singularize}.rb"), force: true
    end

    def create_association_model_file
      @resource.associations&.select(&:has_child?)&.each do |association|
        # association_modelが未定義の場合、skip: trueで作成する
        option = association.field_group.has_association_model? ? { force: true } : { skip: true }
        @writer = ModelWriter.new(association)
        template "model.rb", Rails.root.join("app/models/admin", "#{association.model_name(:snake)}.rb"), **option
      end
    end
  end
end