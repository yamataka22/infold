module Infold
  class Decorator
    include ActiveModel::Model

    attr_reader :field
    attr_accessor :kind,
                  :append,
                  :prepend,
                  :digit

    def initialize(field, **attrs)
      @field = field
      super(**attrs)
    end

  end
end