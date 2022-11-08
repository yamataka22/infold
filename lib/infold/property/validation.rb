module Infold
  class Validation
    include ActiveModel::Model

    attr_reader :field
    attr_accessor :conditions

    def initialize(field)
      @field = field
      self.conditions = []
    end

    def add_conditions(**attrs)
      self.conditions << ValidateCondition.new(**attrs)
    end

    def has_presence_validation?
      conditions.find { |c| c.condition == :presence }
    end

    class ValidateCondition
      include ActiveModel::Model

      attr_writer :condition
      attr_accessor :options

      def condition
        @condition.to_sym
      end
    end
  end
end