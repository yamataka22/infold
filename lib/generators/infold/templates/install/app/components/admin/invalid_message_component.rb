# frozen_string_literal: true

module Admin
    class InvalidMessageComponent < ViewComponent::Base
      def initialize(form, field)
        @message = form.object.errors.full_messages_for(field)&.first
      end

      def render?
        @message.present?
      end

      def call
        "<div class=\"invalid_message\">#{@message}</div>".html_safe
      end
    end
end