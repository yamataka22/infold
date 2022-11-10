module Infold
  class Decorator
    include ActiveModel::Model

    attr_reader :field
    attr_writer :kind
    attr_accessor :append,
                  :prepend,
                  :digit

    def initialize(field, **attrs)
      @field = field
      super(**attrs)
    end

    def kind
      if @kind.blank?
        if field.number?
          :number
        elsif %i(date datetime boolean).include?(field.type)
          field.type
        else
          :string
        end
      else
        @kind.to_sym
      end
    end
  end
end