# frozen_string_literal: true

module Admin
  class SortableComponent < ViewComponent::Base
    def initialize(search, field, label: nil)
      @search = search
      @field = field.to_s
      @label = label
    end

    def dataset
      {
        action: 'index-page#sortChange',
        sort_field: @field,
        sort_kind: current_field? && sort_kind == 'desc' ? 'asc' : 'desc'
      }
    end

    def name
      @label.presence || @search.class.human_attribute_name(@field)
    end

    def current_field?
      @search.sort_field.to_s == @field
    end

    def sort_kind
      @search.sort_kind.to_s
    end

    def sort_status_icon
      "<i class=\"ms-1 bi bi-chevron-#{sort_kind == 'desc' ? 'down' : 'up'}\"></i>".html_safe if current_field?
    end
  end
end