module Infold
  class Enum
    include ActiveModel::Model

    attr_reader :field,
                :elements

    def initialize(field)
      @field = field
      @elements = []
    end

    def add_elements(**attrs)
      (@elements << EnumElement.new(**attrs)).last
    end

    def has_color?
      elements.any? { |e| e.color.present? }
    end

    class EnumElement
      include ActiveModel::Model

      attr_accessor :key,
                    :value,
                    :color

    end
  end
end