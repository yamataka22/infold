require 'infold/writers/base_writer'

module Infold
  class ControllerWriter < BaseWriter
    def app_title
      @app_config.app_title
    end

    def build_new_association_code(if_blank: false)
      code = ''
      @app_config.form_fields&.select { |ff| ff.kind == 'association' }&.map do |form_field|
        code +=
          if @model_config.model_associations.find { |ma| ma.field == form_field.field && ma.kind == 'has_one' }
            "@#{model_name.underscore}.build_#{form_field.field}"
          else
            "@#{model_name.underscore}.#{form_field.field}.build"
          end
        code += " if @#{model_name.underscore}.#{form_field.field}.blank?" if if_blank
        code += "\n"
      end
      inset_indent(code, 3) if code.present?
    end

    def search_params_code
      fields = []
      any_fields = []
      @app_config.search_conditions.each do |condition|
        if condition.sign == 'any'
          any_fields << "[TAB]#{condition.field.pluralize}: []"
        else
          fields << "[TAB]:#{condition.field}"
        end
      end
      fields += %w([TAB]:sort_field [TAB]:sort_kind)
      code = "params[:search]&.permit(\n" + (fields + any_fields).uniq.join(",\n") + "\n)"
      inset_indent(code, 3) if fields.present?
    end

    def post_params_code
      fields = post_params_fields(self_table, @app_config.form_fields)
      fields = fields.join(",\n") if fields.present?
      code = "params.require(:admin_#{model_name.underscore}).permit(\n" + fields.to_s + "\n)"
      inset_indent(code, 3) if fields.present?
    end

    private

      def post_params_fields(table, form_fields)
        fields = []
        form_fields&.sort_by{ |f| f.kind == 'association' ? 9 : 0 }&.each do |form_field|
          column = table.columns.find { |column| column.name == form_field.field }
          if form_field.kind == 'file'
            fields += %W(:#{form_field.field} :remove_#{form_field.field})
          elsif form_field.kind == 'association'
            association_fields = post_params_fields(association_table(form_field.field), form_field.association_fields)
            fields << "#{form_field.field}_attributes: [\n[TAB]" + association_fields.join(",\n[TAB]") + "\n[TAB]]"
          elsif column&.type == 'datetime'
            # datetimeはdateとtimeに分ける
            fields += %W(:#{column.name}_date :#{column.name}_time)
          else
            fields << ":#{form_field.field}"
          end
        end
        fields.map{ |f| "[TAB]#{f}"}
      end
  end
end