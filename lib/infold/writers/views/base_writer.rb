require 'infold/writers/base_writer'

module Infold::Views
  class BaseWriter < Infold::BaseWriter

    attr_reader :app_title

    def initialize(resource, app_title=nil)
      @resource = resource
      @app_title = app_title || @resource.name
    end

    def field_display_code(field, part)
      field_code = "#{resource_name(:snake)}.#{field.name}"
      if part == :csv
        "= #{field_code}#{'_i18n' if field.enum}"
      else
        if field.association&.belongs_to?
          association = "#{resource_name(:snake)}.#{field.association.name}"
          "= link_to #{association}.#{field.association.name_field}, " +
            "#{field.association.belongs_to_show_path(association)}, data: { turbo_frame: 'modal_sub' } if #{association}"
        elsif field.active_storage
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
  end
end