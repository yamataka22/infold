require 'infold/writers/views/base_writer'

module Infold::Views
  class IndexWriter < BaseWriter

    attr_reader :app_title

    def initialize(resource)
      @resource = resource
    end

    def index_conditions; @resource.conditions(:index)&.sort_by { |c| c.index_seq } end
    def index_list_fields; @resource.index_list_fields end
    def csv_fields; @resource.csv_fields end

    def association_search_conditions; @resource.conditions(:association_search)&.sort_by { |c| c.association_seq } end
    def association_search_list_fields; @resource.association_search_list_fields end

    def condition_form_code(condition)
      code = "= render Admin::FieldsetComponent.new(form, " +
        ":#{condition.scope}, :#{condition.form_kind(:index)}, alignment: false, \n" +
        "[TAB]label: Admin::#{resource_name(:model)}.human_attribute_name(:#{condition.field.name})"
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
      "= render Admin::SortableComponent.new(@search, :#{list_field.name}, " +
        "label: Admin::#{resource_name(:model)}.human_attribute_name(:#{list_field.name}))"
    end

    def csv_field_code(csv_field)
      code = "#{resource_name(:snake)}.#{csv_field.name}"
      code = "#{code}_i18n" if csv_field.enum
      code
    end

  end
end
