require 'infold/writers/views/base_writer'

module Infold::Views
  class IndexWriter < BaseWriter

    attr_reader :app_title

    def initialize(resource, app_title=nil)
      @resource = resource
      @app_title = app_title || @resource.name
    end

    def index_conditions; @resource.conditions(:index) end
    def index_list_fields; @resource.index_list_fields end

    def condition_form_code(condition)
      field = condition.field
      code = "= render Admin::FieldsetComponent.new(form, " +
        ":#{condition.scope}, :#{condition.form_kind(:index)}, "

      case condition.form_kind(:index)
      when :association_search
        association = condition.field.association
        code + "association_name: :#{association.name}, " +
          "search_path: #{association.search_path}, " +
          "name_field: :#{association.model_name(:snake)}_#{association.name_field})"
      when :select
        list =
          if field.enum?
            "Admin::#{resource_name}.#{field.name(:multi)}_i18n.invert"
          elsif field.association?
            "Admin::#{field.association.model_name}.all.pluck(:#{field.association.name_field}, :id)"
          end
        code + "list: #{list}, selected_value: form.object.#{condition.scope})"
      when :checkbox
        code + "list: Admin::#{resource_name}.#{field.name(:multi)}_i18n, checked_values: form.object.#{condition.scope})"
      when :switch
        code + "include_hidden: true)"
      else
        datepicker = field.datepicker? ? "datepicker: true" : nil
        if field.decorator&.prepend.present?
          option = "prepend: '#{condition.sign_label} #{field.decorator.prepend}'"
        elsif field.decorator&.append.present?
          option = "prepend: '#{condition.sign_label}', append: '#{field.decorator.append}'"
        else
          option = "prepend: '#{condition.sign_label}'"
        end
        code + "#{[datepicker, option].compact.join(', ')})"
      end
    end

    def list_header_code(list_field)
      "= render Admin::SortableComponent.new(@search, :#{list_field.name})"
    end

  end
end
