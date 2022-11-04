require 'infold/writers/base_writer'

module Infold
  class ViewWriter < BaseWriter
    def search_condition_form_code(condition)
      scope = "#{condition.field}_#{condition.sign.presence || 'eq'}"
      code = "= render Admin::FieldsetComponent.new(form, :#{scope}, "
      association_name = condition.association_name.presence || condition.field.gsub('_id', '')
      association_class_name = resource.model_association_class_name(association_name)
      association_name_field = resource.model_association_name_field(association_name)

      if condition.form_kind == 'association_search' && association_class_name
        code + ":association, association: :#{association_class_name.underscore.pluralize}, " +
          "search_path: #{resource.model_association_search_path(association_name)}, " +
          "name_field: :#{association_class_name.underscore.singularize}_#{association_name_field})"
      elsif condition.form_kind == 'select'
        list =
          if resource.enum?(condition.field)
            "Admin::#{model_name}.#{condition.field.pluralize}_i18n.invert"
          elsif association_class_name
            "Admin::#{association_class_name}.all.pluck(:#{association_name_field}, :id)"
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

    def list_field_header_code(list_field)
      "= render Admin::SortableComponent.new(@search, :#{list_field.field})"
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