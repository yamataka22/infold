require 'infold/writers/base_writer'

module Infold
  class ControllerWriter < BaseWriter

    attr_reader :app_title

    def initialize(resource)
      @resource = resource
    end

    def association_build_code(if_blank: false)
      codes = []
      @resource.association_fields&.select { |af| !af.association.belongs_to? && af.form_element.present?  } &.each do |association_field|
        codes <<
          if association_field.association.has_one?
            "@#{resource_name(:snake)}.build_#{association_field.association.name}"
          else
            "@#{resource_name(:snake)}.#{association_field.association.name}.build"
          end
      end
      indent(codes.join("\n"), 3) if codes.present?
    end

    def search_params_code
      fields = []
      any_fields = []
      @resource.conditions.each do |condition|
        if condition.sign == :any
          any_fields << "[TAB]#{condition.scope}: []"
        else
          fields << "[TAB]:#{condition.scope}"
        end
      end
      fields += %w([TAB]:sort_field [TAB]:sort_kind)
      code = "params[:search]&.permit(\n" + (fields + any_fields).uniq.join(",\n") + "\n)"
      indent(code, 3) if fields.present?
    end

    def post_params_code
      fields = post_params_fields(@resource.form_fields)
      fields = fields.join(",\n") if fields.present?
      code = "params.require(:admin_#{resource_name(:snake)}).permit(\n" + fields.to_s + "\n)"
      indent(code, 3) if fields.present?
    end

    private

      def post_params_fields(form_fields)
        fields = []
        form_fields&.sort_by{ |field| field.form_element.kind_has_association? ? 9 : 0 }&.each do |form_field|
          form_element = form_field.form_element
          if form_element.kind_file?
            fields += %W(:#{form_field.name} :remove_#{form_field.name})
          elsif form_element.kind_has_association?
            association_fields = post_params_fields(form_element.association_fields)
            fields << "#{form_field.name}_attributes: [\n[TAB][TAB]:id,\n[TAB][TAB]:_destroy,\n[TAB]" +
              association_fields.join(",\n[TAB]") + "\n[TAB]]"
          elsif form_element.kind_datetime?
            # datetimeはdateとtimeに分ける
            fields += %W(:#{form_field.name}_date :#{form_field.name}_time)
          else
            fields << ":#{form_field.name}"
          end
        end
        fields.map{ |f| "[TAB]#{f}"}
      end
  end
end