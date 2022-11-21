require 'infold/writers/views/base_writer'

module Infold::Views
  class FormWriter < BaseWriter

    attr_reader :app_title

    def initialize(resource)
      @resource = resource
    end

    def form_fields; @resource.form_fields end

    def form_field_code(field)
      code = "= render Admin::FieldsetComponent.new(form, " +
        ":#{field.name}, :#{field.form_element.form_kind}"
      code += ", required: true" if field.validation&.has_presence?
      case field.form_element.form_kind
      when :association_search
        "#{code}, #{belongs_to_search_form_option(field.association)})"
      when :select
        "#{code}, list: #{form_field_list(field)}, " +
          "selected_value: form.object.#{field.name})"
      when :radio
        "#{code}, list: #{form_field_list(field)})"
      when :datetime
        "#{code})"
      when :file
        "#{code})"
      when :switch
        "#{code})"
      else
        option = text_form_option(field).presence
        option ? "#{code}, #{option})" : "#{code})"
      end
    end
  end
end