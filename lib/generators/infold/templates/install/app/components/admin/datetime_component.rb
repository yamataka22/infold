# frozen_string_literal: true

module Admin
  class DatetimeComponent < ViewComponent::Base
    def initialize(form, field)
      @form = form
      @field = field
    end
  end
end