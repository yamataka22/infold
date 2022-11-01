require 'infold/writers/base_writer'

module Infold
  class SearchFormWriter < BaseWriter
    def set_conditions_code
      fields = @app_config.search_conditions.map{ |c| ":#{c.field}_#{c.sign}" }
      return if fields.blank?
      code = "set_condition #{fields.join(",\n[TAB]")}\n"
      inset_indent(code, 2).presence
    end


  end
end