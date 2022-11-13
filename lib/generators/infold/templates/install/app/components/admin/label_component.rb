# frozen_string_literal: true

module Admin
  class LabelComponent < ViewComponent::Base
    def initialize(form, field, required: false)
      @form = form
      @field = field
      @required = required ? 'required' : nil
    end

    def call
      @form.label @field, class: "form-label fw-bold #{@required}"
    end
  end
end