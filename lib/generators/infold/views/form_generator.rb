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
        # @writer.form_fields.each do |field|
        #   if field.association&.has_many? || field.association&.has_one?
        #     @association_field = field
        #     # [TODO] association先のyamlを読み込むしかないか
        #     # association先のyamlを読み込んで、その先にあるbelongs_toの情報を取得
        #     association_name = field.association.name.underscore.singularize
        #     association_yaml = Rails.root.join("config/infold/#{association_name}.yml")
        #     if File.exist?(association_yaml)
        #       yaml = YAML.load_file(association_yaml)
        #       yaml_reader = YamlReader.new(association_name, yaml, @db_schema)
        #       association_resource = Resource.new(association_name, yaml_reader.fields)
        #       # association先のリソースのform_fieldsに、自分のassociation先のform_fieldsを設定する
        #       association_resource.merge_form_fields(field.form_element.association_fields)
        #       @association_writer = FormWriter.new(association_resource, yaml_reader.app_title)
        #     end
        #     template "views/_form_association.haml",
        #              Rails.root.join("app/views/admin/#{name.underscore.pluralize}/_form_#{field.name}.html.haml"), force: true
        #   end
        # end
      end
    end
  end
end