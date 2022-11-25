# frozen_string_literal: true

module Admin
  class LabelComponent < ViewComponent::Base
    def initialize(form, field, label: nil, required: false)
      @form = form
      @field = field
      @label = label
      @required = required ? 'required' : nil
    end

    def call
      @form.label @field, @label, class: "form-label fw-bold text-muted #{@required}"
    end
  end
end