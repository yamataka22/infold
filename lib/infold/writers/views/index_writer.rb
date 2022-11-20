require 'infold/writers/views/base_writer'

module Infold::Views
  class IndexWriter < BaseWriter

    attr_reader :app_title

    def initialize(resource)
      @resource = resource
    end

    def index_conditions; @resource.conditions(:index) end
    def index_list_fields; @resource.index_list_fields end

    def condition_form_code(condition)
      code = "= render Admin::FieldsetComponent.new(form, " +
        ":#{condition.scope}, :#{condition.form_kind(:index)}"
      case condition.form_kind(:index)
      when :association_search
        "#{code}, #{belongs_to_search_form_option(condition.field.association)})"
      when :select
        "#{code}, list: #{form_field_list(condition.field)}, " +
          "selected_value: form.object.#{condition.scope})"
      when :checkbox
        "#{code}, #{checkbox_form_option(condition.field, condition.scope)})"
      when :switch
        "#{code}, include_hidden: false)"
      else
        option = text_form_option(condition.field, placeholder: condition.sign_label).presence
        option ? "#{code}, #{option})" : "#{code})"
      end
    end

    def list_header_code(list_field)
      "= render Admin::SortableComponent.new(@search, :#{list_field.name})"
    end

  end
end
