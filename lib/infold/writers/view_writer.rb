require 'infold/writers/base_writer'

module Infold
  class ViewWriter < BaseWriter
    def search_condition_form_code(condition)
      field = condition.field
      code = "= render Admin::FieldsetComponent.new(form, :#{condition.scope}, :#{condition.form_kind(:index)}, "
      code +
        case condition.form_kind(:index)
        when :association_search
          association = condition.field.association
          "association_name: :#{association.association_name}, " +
            "search_path: #{association.search_path}, " +
            "name_field: :#{association.model_name(:single, :snake)}_#{association.name_field})"
        when :select
          list =
            if field.enum?
              "Admin::#{model_name}.#{field.name(:multi)}_i18n.invert"
            elsif field.association?
              "Admin::#{field.association.model_name}.all.pluck(:#{field.association.name_field}, :id)"
            end
          "list: #{list}, selected_value: form.object.#{condition.scope})"
        when :checkbox
          "list: Admin::#{model_name}.#{field.name(:multi)}_i18n, checked_values: form.object.#{condition.scope})"
        when :switch
          "include_hidden: true)"
        else
          datepicker = field.datepicker? ? "datepicker: true" : nil
          if field.decorator&.prepend.present?
            option = "prepend: '#{condition.sign_label} #{field.decorator.prepend}'"
          elsif field.decorator&.append.present?
            option = "prepend: '#{condition.sign_label}', append: '#{field.decorator.append}'"
          else
            option = "prepend: '#{condition.sign_label}'"
          end
          "#{[datepicker, option].compact.join(', ')})"
        end
    end

    def index_list_header_code(list_field)
      "= render Admin::SortableComponent.new(@search, :#{list_field.field})"
    end

    def index_row_code(list_field)
      column = table.columns.find { |c| c.name == list_field.field }
      return "= #{list_field}" unless column
      if column.type == ''
        'aaa'
      end
    end
  end
end