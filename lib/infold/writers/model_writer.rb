require 'infold/writers/base_writer'

module Infold
  class ModelWriter < BaseWriter

    def self_table
      db_schema.table(@resource_config.resource_name)
    end

    def model_name
      self_table.model_name
    end

    def association_code
      code = ''
      @resource_config.model_associations&.each do |model_association|
        code += "#{model_association[:kind]} :#{model_association[:name]}"
        options = model_association[:options]&.map { |key, value| "#{key}: '#{value}'" }
        code += ", #{options.join(', ')}" if options.present?
        code += "\n"
      end
      if @resource_config.form_associations.present?
        code += "\n"
        @resource_config.form_associations.each do |form_association|
          code += "accepts_nested_attributes_for :#{form_association}, reject_if: :all_blank, allow_destroy: true\n"
        end
      end

      inset_indent(code, 2).presence
    end

    def datetime_field_code
      code = ''
      self_table.datetime_columns.each do |column|
        code += "datetime_field :#{column}\n"
      end
      inset_indent(code, 2).presence
    end

    def active_storage_attachment_code
      code = ''
      @resource_config.setting.model&.active_storage&.each do |field, options|
        code += "has_one_attached :#{field}"
      end
    end

    def validation_code

    end

    def enum_code

    end

    def delegate_code

    end

    def scope_code

    end

    private

      def options(code, options)
        if options.present?
          options = options.map { |key, value| "#{key}: '#{value}'" }
          code += ", #{options.join(', ')}"
        end
        code
      end
  end
end