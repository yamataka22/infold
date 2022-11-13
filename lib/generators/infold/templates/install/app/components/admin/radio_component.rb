# frozen_string_literal: true

module Admin
  class RadioComponent < ViewComponent::Base
    def initialize(form, field, list, checked_value: nil, html_class: nil)
      @form = form
      @field = field
      @list = list
      @checked_value = checked_value
      @class = html_class
    end

    def radio_button(key)
      classes = %W(form-check-input #{@class})
      classes << 'is-invalid' if helpers.admin_field_invalid?(@form, @field)
      @form.radio_button(@field,
                         key,
                         class: classes.join(' '),
                         checked: key == (@checked_value || @form.object.send(@field)).to_s)
    end
  end
end