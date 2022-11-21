require "active_support/core_ext/hash/indifferent_access"

module Infold
  class Validation
    include ActiveModel::Model

    attr_reader :field
    attr_accessor :conditions

    def initialize(field)
      @field = field
      self.conditions = []
    end

    def add_conditions(condition, options)
      self.conditions << ValidateCondition.new(condition, options)
    end

    def has_presence?
      conditions.find { |c| c.condition == :presence }
    end

    class ValidateCondition
      include ActiveModel::Model

      attr_accessor :options

      def initialize(condition, options)
        @condition = condition
        @options = options&.with_indifferent_access
      end

      def condition
        @condition.to_sym
      end
    end
  end
end