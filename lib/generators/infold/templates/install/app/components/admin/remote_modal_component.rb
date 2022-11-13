# frozen_string_literal: true

module Admin
  class RemoteModalComponent < ViewComponent::Base
    renders_one :header
    renders_one :body
    renders_one :footer

    def initialize(kind=nil, backdrop: nil)
      @remote_modal_kind = kind || 'modal_main'
      @backdrop = backdrop
    end
  end
end