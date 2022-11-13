# frozen_string_literal: true

module Admin
  class SelectComponent < ViewComponent::Base
    def initialize(form, field, list, blank:true, selected_value:nil)
      @form = form
      @field = field
      @list = list
      @blank = blank
      @selected_value = selected_value
    end

    def select_field
      classes = %W(form-select #{@class})
      classes << 'is-invalid' if helpers.admin_field_invalid?(@form, @field)
      @form.select(@field, @list,
                   { include_blank: @blank,
                     selected: @selected_value || @form.object.send(@field).to_s },
                   { class: classes.join(' ') })
    end

    def call
      select_field
    end
  end
end