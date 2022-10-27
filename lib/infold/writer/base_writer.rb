require 'infold/resource_config'
require 'infold/db_schema'
require 'infold/table'

module Infold
  class BaseWriter

    attr_reader :table

    def initialize(resource_name)
      @resource_config = ResourceConfig.new(resource_name)
      @table = DbSchema.read_schema(resource_name)
    end

    def inset_indent(code, size, first_row: false)
      return unless code
      indent = '  ' * size
      code.gsub!(/^/, indent)
      code.sub!(indent, '') unless first_row
      code
    end
  end
end