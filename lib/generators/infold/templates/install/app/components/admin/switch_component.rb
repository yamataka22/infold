# frozen_string_literal: true

module Admin
  class SwitchComponent < ViewComponent::Base
    def initialize(form, field, include_hidden: true)
      @form = form
      @field = field
      @include_hidden = include_hidden
    end

    def switch
      classes = %W(form-check-input)
      classes << 'is-invalid' if helpers.admin_field_invalid?(@form, @field)
      @form.check_box(@field, class: classes.join(' '), include_hidden: @include_hidden)
    end
  end
end