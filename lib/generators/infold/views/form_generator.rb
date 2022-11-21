require 'rails/generators/base'
require 'infold/writers/views/form_writer'
require 'infold/resource'
require 'infold/db_schema'
require 'infold/yaml_reader'

module Infold
  module Views
    class FormGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __dir__)

      def setup
        resource_name = name.camelize.singularize
        db_schema = DbSchema.new(File.read(Rails.root.join('db/schema.rb')))
        yaml = YAML.load_file(Rails.root.join("config/infold/#{resource_name.underscore}.yml"))
        resource = YamlReader.generate_resource(resource_name, yaml, db_schema)
        @writer = FormWriter.new(resource)
      end

      def new_file
        template "views/new.html+turbo_frame.haml",
                 Rails.root.join("app/views/admin/#{name.underscore.pluralize}/new.html+turbo_frame.haml"), force: true
      end

      def edit_file
        template "views/edit.html+turbo_frame.haml",
                 Rails.root.join("app/views/admin/#{name.underscore.pluralize}/edit.html+turbo_frame.haml"), force: true
      end

      def form_file
        template "views/_form.haml",
                 Rails.root.join("app/views/admin/#{name.underscore.pluralize}/_form.html.haml"), force: true
      end

      def association_form_file
        @writer.form_fields.each do |field|
          if field.association&.has_many? || field.association&.has_one?
            @association_field = field
            template "views/_form_association.haml",
                     Rails.root.join("app/views/admin/#{name.underscore.pluralize}/_form_#{field.name}.html.haml"), force: true
          end
        end
      end
    end
  end
end