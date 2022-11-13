# frozen_string_literal: true

module Admin
    class CheckboxComponent < ViewComponent::Base
      def initialize(form, field, list, checked_values: nil, html_class: nil, multiple: true)
        @form = form
        @field = field
        @list = list
        @checked_values = checked_values
        @class = html_class
        @multiple = multiple
      end

      def checkbox(key)
        classes = %W(form-check-input #{@class})
        classes << 'is-invalid' if helpers.admin_field_invalid?(@form, @field)
        @form.check_box(@field, { multiple: @multiple,
                                class: classes.join(' '),
                                checked: @checked_values&.include?(key) }, key, nil)
      end
    end
end