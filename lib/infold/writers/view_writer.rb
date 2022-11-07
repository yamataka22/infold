require 'infold/writers/base_writer'

module Infold
  class ViewWriter < BaseWriter
    def search_condition_form_code(condition)
      scope = "#{condition.field}_#{condition.sign.presence || 'eq'}"
      code = "= render Admin::FieldsetComponent.new(form, :#{scope}, "
      association_name = condition.association_name.presence || condition.field.gsub('_id', '')
      model_association = resource.model_associations&.find { |ma| ma.association_name == association_name }

      if condition.form_kind == 'association_search' && model_association
        code + ":association, association: :#{model_association.class_name.underscore.pluralize}, " +
          "search_path: #{model_association.search_path}, " +
          "name_field: :#{model_association.class_name.underscore.singularize}_#{model_association.name_field})"
      elsif condition.form_kind == 'select'
        list =
          if resource.enum?(condition.field)
            "Admin::#{model_name}.#{condition.field.pluralize}_i18n.invert"
          elsif model_association
            "Admin::#{model_association.class_name}.all.pluck(:#{model_association.name_field}, :id)"
          end
        code + ":select, list: #{list}, selected_value: form.object.#{scope})"
      elsif condition.form_kind == 'radio'
        # [TODO]
      elsif condition.sign == 'any' && resource.enum?(condition.field)
        code + ":checkbox, list: Admin::#{model_name}.#{condition.field.pluralize}_i18n, " +
          "checked_values: form.object.#{scope})"
      elsif condition.form_kind == 'switch'
        code + ":switch, include_hidden: false)"
      else
        datepicker = resource.self_table.columns.find { |c| %w(date datetime).include?(c.type) && c.name == condition.field }
        datepicker = ", datepicker: true" if datepicker
        decorator = resource.decorators&.find { |d| d.field == condition.field }
        sign = if decorator&.prepend.present?
                ", prepend: '#{sign_label(condition.sign)} #{decorator.prepend}'"
              elsif decorator&.append.present?
                ", prepend: '#{sign_label(condition.sign)}', append: '#{decorator.append}'"
              else
                ", prepend: '#{sign_label(condition.sign)}'"
               end
        code + ":text#{datepicker}#{sign})"
      end
    end

    def index_list_header_code(list_field)
      "= render Admin::SortableComponent.new(@search, :#{list_field.field})"
    end

    def index_row_code(list_field)
      column = self_table.columns.find { |c| c.name == list_field.field }
      return "= #{list_field}" unless column
      if column.type == ''
        'aaa'
      end
    end

    def sign_label(sign)
      case sign.to_s
      when 'lteq' then 'or less'
      when 'gteq' then 'or more'
      when 'full_like' then 'like %@%'
      when 'start_with' then 'like @%'
      else '='
      end
    end
  end
end