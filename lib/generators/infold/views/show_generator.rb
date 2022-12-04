require 'rails/generators/base'
require 'infold/writers/views/show_writer'
require 'infold/resource'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  module Views
    class ShowGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __dir__)

      def setup
        resource_name = name.camelize.singularize
        db_schema_file = Rails.root.join('db/schema.rb')
        db_schema = DbSchema.new(File.exist?(db_schema_file) ? File.read(db_schema_file) : nil)
        yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
        resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
        @writer = ShowWriter.new(resource)
      end

      def show_file
        template "views/show.html+turbo_frame.haml", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/show.html+turbo_frame.haml"), force: true
      end

      def show_wrapper_file
        template "views/_show_wrapper.haml", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/_show_wrapper.html.haml"), force: true
      end

      def show_content_file
        template "views/_show_content.haml", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/_show_content.html.haml"), force: true
      end
    end
  end
end