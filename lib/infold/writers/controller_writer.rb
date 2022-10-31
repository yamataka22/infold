require 'infold/writers/base_writer'

module Infold
  class ControllerWriter < BaseWriter
    def app_title
      @app_config.app_title
    end

    def build_new_association_code
      code = @app_config.form_fields&.select { |ff| ff.kind == 'associations' }&.map do |form_field|
        if @model_config.model_associations.find { |ma| ma.field == form_field.field && ma.kind == 'has_one' }
          "@#{model_name.underscore}.build_#{form_field.field}"
        else
          "@#{model_name.underscore}.#{form_field.field}.build"
        end
      end
      inset_indent(code.join("\n") + "\n", 2) if code.present?
    end

    def search_params_code

    end

    def post_params_code

    end
  end
end