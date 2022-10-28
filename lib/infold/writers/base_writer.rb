# require 'infold/resource_config'
# require 'infold/db_schema'

module Infold
  class BaseWriter

    attr_reader :resource_config,
                :db_schema

    def initialize(resource_config, db_schema)
      @resource_config = resource_config
      @db_schema = db_schema
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