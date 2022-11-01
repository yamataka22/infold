require "active_support/core_ext/hash/indifferent_access"

module Infold
  # resource.ymlをhashに展開する役割
  class ModelConfig
    attr_reader :resource_name,
                :model,
                :app

    def initialize(resource_name, yaml)
      @resource_name = resource_name
      @model = yaml.dig('model').to_h.with_indifferent_access
      @app = yaml.dig('app').to_h.with_indifferent_access
    end

    ModelAssociation = Struct.new( :kind, :field, :options )
    def model_associations
      @model.dig(:association)&.map do |field, options|
        model_association =  ModelAssociation.new
        model_association.field = field
        model_association.kind = options.dig(:kind)
        model_association.options = options.reject { |k| k == 'kind' }
        model_association
      end
    end

    FormAssociation = Struct.new( :field )
    def form_associations
      model_association_fields = model_associations.map { |ma| %w(has_many has_one).include?(ma.kind) ? ma.field : nil }.compact
      @app.dig(:form, :fields)&.map do |form_field|
        field = hash_key_or_string(form_field)
        FormAssociation.new(field) if model_association_fields.include?(field)
      end&.compact
    end

    ActiveStorage = Struct.new( :field, :kind, :thumb )
    ActiveStorageThumb = Struct.new( :kind, :width, :height )
    def active_storages
      @model.dig(:active_storage)&.map do |field, options|
        thumb = nil
        if options&.dig(:kind) == 'image' && options.dig(:thumb).present?
          thumb = ActiveStorageThumb.new(options.dig(:thumb, :kind),
                                         options.dig(:thumb, :width),
                                         options.dig(:thumb, :height))
        end
        ActiveStorage.new(field, options.dig(:kind), thumb)
      end
    end

    Validate = Struct.new( :field, :conditions )
    ValidateCondition = Struct.new( :condition, :options )
    def validates
      model.dig(:validate)&.map do |field, condition|
        validate = Validate.new(field, [])
        if condition.is_a?(String)
          validate.conditions << ValidateCondition.new(condition)
        elsif condition.is_a?(Array)
          condition.each do |cond|
            if cond.is_a?(String)
              validate.conditions << ValidateCondition.new(cond)
            else
              validate.conditions << ValidateCondition.new(cond.keys[0], cond[cond.keys[0]])
            end
          end
        end
        validate
      end
    end

    Enum = Struct.new( :field, :elements )
    EnumElement = Struct.new( :key, :value, :color )
    def enum
      model.dig(:enum)&.map do |field, elements|
        enum = Enum.new(field)
        enum.elements = elements.map do |key, options|
          element = EnumElement.new
          element.key = key
          if options.is_a?(Hash)
            element.value = options.dig(:value)
            element.color = options.dig(:color)
          else
            element.value = options
          end
          element
        end
        enum
      end
    end

    Decorator = Struct.new( :field, :append, :prepend, :digit )
    def decorator
      model.dig(:decorate)&.map do |field, options|
        decorator = Decorator.new
        decorator.field = field
        decorator.append = options.dig(:append)
        decorator.prepend = options.dig(:prepend)
        decorator.digit = options.dig(:digit)
        decorator
      end
    end

    private

      # HashキーまたはStringを返す
      def hash_key_or_string(value)
        value.is_a?(Hash) ? value.keys[0] : value
      end
  end
end