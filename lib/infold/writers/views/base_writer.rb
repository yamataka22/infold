require 'infold/writers/base_writer'

module Infold::Views
  class BaseWriter < Infold::BaseWriter

    attr_reader :app_title

    def initialize(resource, app_title=nil)
      @resource = resource
      @app_title = app_title || @resource.name
    end

    def field_display_code(field, part, model_name: nil)
      field_code = "#{model_name || resource_name(:snake)}.#{field.name}"
      if part == :csv
        "= #{field_code}#{'_i18n' if field.enum}"
      else
        if field.association&.belongs_to?
          belongs_to_field_display(field.association, model_name)
        elsif field.active_storage
          active_storage_field_display(field, part, field_code)
        elsif field.enum&.has_color?
          "= render Admin::BadgeComponent.new(#{field_code}_i18n, #{field_code}_color)"
        elsif field.enum
          "= #{field_code}_i18n"
        elsif field.decorator
          "= #{field_code}_display"
        else
          "= #{field_code}"
        end
      end
    end

    protected

    def belongs_to_field_display(association, model_name=nil)
      association_field = "#{model_name || resource_name(:snake)}.#{association.name}"
      "= link_to #{association_field}.#{association.name_field}, " +
        "#{association.belongs_to_show_path(association_field)}, " +
        "data: { turbo_frame: 'modal_sub' } if #{association_field}"
    end

    def active_storage_field_display(field, part, field_code)
      code = <<-CODE.gsub(/^\s+/, '')
          - if #{field_code}.attached?
          <%- if field.active_storage.kind_file? -%>
            [TAB]= link_to #{field_code}.filename, rails_blob_url(#{field_code}), target: '_blank'
          <%- else -%>
            [TAB]= link_to url_for(#{field_code}), target: '_blank' do
            [TAB][TAB]- if #{field_code}.blob.image?
            <%- if part == :list && field.active_storage.thumb? -%>
              [TAB][TAB][TAB]= image_tag(#{field_code}.variant(:thumb), class: 'img-fluid')
            <%- else -%>
              [TAB][TAB][TAB]= image_tag(#{field_code}, class: 'img-fluid')
            <%- end -%>
            [TAB][TAB]- else
            [TAB][TAB][TAB]= #{field_code}.filename
          <%- end -%>
      CODE
      ERB.new(code, trim_mode: '-').result(binding)
    end

    def belongs_to_search_form_option(association)
      "association_name: :#{association.name}, " +
        "search_path: #{association.search_path}, " +
        "name_field: :#{association.model_name(:snake)}_#{association.name_field}"
    end

    def checkbox_form_option(field, name)
      "list: Admin::#{resource_name}.#{field.name(:multi)}_i18n, " +
        "checked_values: form.object.#{name}"
    end

    def form_field_list(field)
      if field.enum?
        "Admin::#{resource_name}.#{field.name(:multi)}_i18n.invert"
      elsif field.association?
        "Admin::#{field.association.model_name}.all.pluck(:#{field.association.name_field}, :id)"
      end
    end

    def text_form_option(field, placeholder: nil)
      datepicker = prepend = append = nil
      datepicker = "datepicker: true" if field.datepicker?
      prepend = "prepend: '#{field.decorator.prepend}'" if field.decorator&.prepend.present?
      append = "append: '#{field.decorator.append}'" if field.decorator&.append.present?
      placeholder = "placeholder: '#{placeholder}'" if placeholder.present?
      [datepicker, prepend, append, placeholder].compact.join(', ')
    end
  end
end