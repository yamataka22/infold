require 'infold/writers/base_writer'

module Infold
  module Views
    class IndexWriter < BaseWriter

      attr_reader :app_title

      def initialize(resource, app_title=nil)
        @resource = resource
        @app_title = app_title || @resource.name
      end

      def index_conditions; @resource.conditions(:index) end
      def index_list_fields; @resource.index_list_fields end

      def search_condition_form_code(condition)
        field = condition.field
        code = "= render Admin::FieldsetComponent.new(form, :#{condition.scope}, :#{condition.form_kind(:index)}, "
        code +
          case condition.form_kind(:index)
          when :association_search
            association = condition.field.association
            "association_name: :#{association.name}, " +
              "search_path: #{association.search_path}, " +
              "name_field: :#{association.model_name(:snake)}_#{association.name_field})"
          when :select
            list =
              if field.enum?
                "Admin::#{resource_name}.#{field.name(:multi)}_i18n.invert"
              elsif field.association?
                "Admin::#{field.association.model_name}.all.pluck(:#{field.association.name_field}, :id)"
              end
            "list: #{list}, selected_value: form.object.#{condition.scope})"
          when :checkbox
            "list: Admin::#{resource_name}.#{field.name(:multi)}_i18n, checked_values: form.object.#{condition.scope})"
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
        "= render Admin::SortableComponent.new(@search, :#{list_field.name})"
      end

      def index_list_value_code(list_field, decorate: true)
        field_code = "#{resource_name(:snake)}.#{list_field.name}"
        if list_field.association&.belongs_to?
          "= #{resource_name(:snake)}.#{list_field.association.name_field}"
        elsif list_field.active_storage
          code = <<-CODE.gsub(/^\s+/, '')
            - if #{field_code}.attached?
            <%- if list_field.active_storage.kind_file? -%>
            [TAB]= link_to #{field_code}.filename, rails_blob_url(#{field_code}), target: '_blank'
            <%- else -%>
            [TAB]= link_to url_for(#{field_code}), target: '_blank' do
            [TAB][TAB]- if #{field_code}.blob.image?
            [TAB][TAB][TAB]= image_tag(#{field_code}#{'.variant(:thumb)' if list_field.active_storage.thumb?}, class: 'img-fluid')
            [TAB][TAB]- else
            [TAB][TAB][TAB]= #{field_code}.filename
            <%- end -%>
          CODE
          ERB.new(code, nil, '-').result(binding)
        elsif list_field.enum&.has_color?
          "= render Admin::BadgeComponent.new(#{field_code}_i18n, #{field_code}_color)"
        elsif list_field.enum
          "= #{field_code}_i18n"
        elsif decorate && list_field.decorator
          "= #{field_code}_display"
        else
          "= #{field_code}"
        end
      end
    end
  end
end