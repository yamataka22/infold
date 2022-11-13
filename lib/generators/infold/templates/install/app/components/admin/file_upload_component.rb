# frozen_string_literal: true

module Admin
  class FileUploadComponent < ViewComponent::Base
    def initialize(form, field)
      @form = form
      @field = field
    end
  end
end