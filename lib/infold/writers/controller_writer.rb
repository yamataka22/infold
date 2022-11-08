require 'infold/writers/base_writer'

module Infold
  class ControllerWriter < BaseWriter
    def app_title
      @resource.app_title
    end

    def association_new_code(if_blank: false)
      code = ''
      @resource.association_fields&.select { |af| af.form_element.present?  } &.each do |association_field|
        code +=
          if association_field.association.has_one?
            "@#{model_name(:snake)}.build_#{association_field.name}"
          else
            "@#{model_name(:snake)}.#{association_field.name}.build"
          end
        code += " if @#{model_name(:snake)}.#{association_field.name}.blank?" if if_blank
        code += "\n"
      end
      inset_indent(code, 3) if code.present?
    end

    def search_params_code
      fields = []
      any_fields = []
      @resource.conditions.each do |condition|
        if condition.sign == :any
          any_fields << "[TAB]#{condition.field.name(:multi)}: []"
        else
          fields << "[TAB]:#{condition.field.name}"
        end
      end
      fields += %w([TAB]:sort_field [TAB]:sort_kind)
      code = "params[:search]&.permit(\n" + (fields + any_fields).uniq.join(",\n") + "\n)"
      inset_indent(code, 3) if fields.present?
    end

    def post_params_code
      fields = post_params_fields(@resource.form_element_fields)
      fields = fields.join(",\n") if fields.present?
      code = "params.require(:admin_#{model_name.underscore}).permit(\n" + fields.to_s + "\n)"
      inset_indent(code, 3) if fields.present?
    end

    private

      def post_params_fields(form_element_fields)
        fields = []
        form_element_fields&.sort_by{ |f| f.form_element.kind_association? ? 9 : 0 }&.each do |form_element_field|
          form_element = form_element_field.form_element
          if form_element.kind_file?
            fields += %W(:#{form_element_field.name} :remove_#{form_element_field.name})
          elsif form_element.kind_association?
            association_fields = post_params_fields(form_element.association_fields)
            fields << "#{form_element_field.name}_attributes: [\n[TAB]" + association_fields.join(",\n[TAB]") + "\n[TAB]]"
          elsif form_element.kind_datetime?
            # datetimeはdateとtimeに分ける
            fields += %W(:#{form_element_field.name}_date :#{form_element_field.name}_time)
          else
            fields << ":#{form_element_field.name}"
          end
        end
        fields.map{ |f| "[TAB]#{f}"}
      end
  end
end