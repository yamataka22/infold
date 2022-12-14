require 'rails/generators/base'
require 'infold/writers/views/index_writer'
require 'infold/resource'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  module Views
    class IndexGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __dir__)

      def setup
        resource_name = name.camelize.singularize
        db_schema_file = Rails.root.join('db/schema.rb')
        db_schema = DbSchema.new(File.exist?(db_schema_file) ? File.read(db_schema_file) : nil)
        yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
        resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
        @writer = IndexWriter.new(resource)
      end

      def index_file
        template "views/index.haml", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/index.html.haml"), force: true
      end

      def index_row_file
        template "views/_index_row.haml", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/_index_row.html.haml"), force: true
      end

      def index_turbo_frame_file
        template "views/index.html+turbo_frame.haml", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/index.html+turbo_frame.haml"), force: true
      end

      def csv_file
        template "views/index.csv.ruby", Rails.root.join("app/views/admin/#{name.underscore.pluralize}/index.csv.ruby"), force: true
      end
    end
  end
end