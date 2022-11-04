# require 'infold/model_config'
# require 'infold/db_schema'

module Infold
  class BaseWriter

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    def model_name
      @resource.self_table&.model_name
    end

    def inset_indent(code, size, first_row: false)
      return unless code
      indent = '  ' * size
      code.gsub!(/^/, indent)
      code.sub!(indent, '') unless first_row
      code
    end

    def association_table(association_name)
      model_association = @resource.model_associations&.
        find { |model_association| model_association.association_name == association_name }
      table_name = model_association&.class_name&.underscore&.pluralize ||
        model_association.association_name.pluralize
      @resource.table(table_name)
    end

    def index_path
      "admin_#{model_name.underscore.pluralize}_path"
    end

    def new_path
      "new_admin_#{model_name.underscore}_path"
    end
  end
end