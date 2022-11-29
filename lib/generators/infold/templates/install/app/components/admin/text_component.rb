# frozen_string_literal: true

module Admin
    class TextComponent < ViewComponent::Base
      def initialize(form, field, form_kind: nil, datepicker: false, timepicker: false, html_class: nil, placeholder: nil, rows: nil, data: nil)
        @form = form
        @field = field
        @form_kind = form_kind || 'text_field'
        @datepicker = datepicker
        @timepicker = timepicker
        @class = html_class
        @data = data || {}
        @placeholder = placeholder
        @rows = rows
      end

      def text_field
        if @datepicker
          @data[:controller] = 'datepicker'
        elsif @timepicker
          @data[:controller] = 'timepicker'
        end
        classes = %W(form-control #{@class})
        classes << 'datepicker' if @datepicker
        classes << 'timepicker' if @timepicker
        classes << 'is-invalid' if helpers.admin_field_invalid?(@form, @field)
        @form.send(@form_kind, @field,
                   class: classes.join(' '),
                   placeholder: @placeholder,
                   data: @data,
                   rows: @rows,
                   autocomplete: 'off',
                   step: @form_kind == 'number_field' ? :any : nil)
      end

      def call
        text_field
      end
    end
end