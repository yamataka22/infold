# frozen_string_literal: true

module Admin
  class BadgeComponent < ViewComponent::Base
    def initialize(name, color)
      @name = name
      @color = color
    end

    def badge_class
      "badge bg-#{@color}" if @color.present?
    end

    def call
      "<span class=\"#{badge_class}\">#{@name}</span>".html_safe if @name.present?
    end
  end
end