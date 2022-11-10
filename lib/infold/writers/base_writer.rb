module Infold
  class BaseWriter

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    def inset_indent(code, size, first_row: false)
      return unless code
      indent = '  ' * size
      code.gsub!(/^/, indent)
      code.sub!(indent, '') unless first_row
      code
    end

    def index_path
      "admin_#{resource_name(:snake, :multi)}_path"
    end

    def new_path
      "new_admin_#{resource_name(:snake)}_path"
    end

    def show_path(object)
      "admin_#{resource_name(:snake)}_path(#{object})"
    end

    def edit_path(object)
      "edit_admin_#{resource_name(:snake)}_path(#{object})"
    end

    def resource_name(*attr)
      name = @resource.name
      name = name.underscore if attr.include?(:snake)
      name = name.camelize if attr.include?(:camel)
      name = name.singularize if attr.include?(:single)
      name = name.pluralize if attr.include?(:multi)
      name
    end
  end
end