# require 'infold/model_config'
# require 'infold/db_schema'

module Infold
  class BaseWriter

    attr_reader :model_config,
                :app_config,
                :db_schema

    def initialize(model_config, app_config, db_schema)
      @model_config = model_config
      @app_config = app_config
      @db_schema = db_schema
    end

    def self_table
      db_schema&.table(@model_config.resource_name)
    end

    def model_name
      self_table&.model_name
    end

    def inset_indent(code, size, first_row: false)
      return unless code
      indent = '  ' * size
      code.gsub!(/^/, indent)
      code.sub!(indent, '') unless first_row
      code
    end

    def association_table(association_name)
      model_association = @model_config.model_associations&.
        find { |model_association| model_association.field == association_name }
      table_name = model_association&.options&.dig(:class_name)&.underscore&.pluralize ||
        model_association.field.pluralize
      db_schema.table(table_name)
    end

    def index_path
      "admin_#{model_name.underscore.pluralize}_path"
    end
  end
end