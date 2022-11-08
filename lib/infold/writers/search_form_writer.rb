require 'infold/writers/base_writer'

module Infold
  class SearchFormWriter < BaseWriter
    def set_conditions_code
      fields = @resource.conditions.map{ |c| ":#{c.field.name}_#{c.sign}" }
      return if fields.blank?
      code = "set_condition #{fields.join(",\n[TAB][TAB][TAB][TAB][TAB][TAB][TAB]")}\n"
      inset_indent(code, 2).presence
    end

    def record_search_include_code
      # includes belongs_to associations
      includes = @resource.associations&.select(&:belongs_to?)
      ".includes(:#{includes.map(&:association_name).join(', :')})" if includes.present?
    end
  end
end