require 'infold/writers/base_writer'

module Infold
  class SearchFormWriter < BaseWriter

    def initialize(resource)
      @resource = resource
    end

    def set_conditions_code
      fields = @resource.conditions&.map{ |c| ":#{c.field.name}_#{c.sign}" }&.uniq
      return if fields.blank?
      code = "set_condition #{fields.join(",\n[TAB][TAB][TAB][TAB][TAB][TAB][TAB]")}\n"
      indent(code, 2).presence
    end

    def record_search_includes_code
      # includes belongs_to associations
      includes = @resource.associations&.select(&:belongs_to?)
      ".includes(:#{includes.map(&:name).join(', :')})" if includes.present?
    end
  end
end