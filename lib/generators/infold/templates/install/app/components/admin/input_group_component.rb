# frozen_string_literal: true

module Admin
    class InputGroupComponent < ViewComponent::Base
      def initialize(append: nil, prepend: nil)
        @append = append
        @prepend = prepend
      end
    end
end