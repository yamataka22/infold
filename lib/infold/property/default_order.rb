module Infold
  class DefaultOrder

    attr_reader :resource,
                :field,
                :order_kind

    def initialize(resource, field, order_kind)
      @resource = resource
      @field = field
      @order_kind = order_kind
    end
  end
end