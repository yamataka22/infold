require "active_support/core_ext/hash/indifferent_access"

module Infold
  module ResourceModel

    ModelAssociation = Struct.new( :kind, :association_name, :class_name, :foreign_key, :dependent, :name_field )
    def model_associations
      model.dig(:association)&.map do |association_name, options|
        model_association =  ModelAssociation.new
        model_association.association_name = association_name
        model_association.kind = options.dig(:kind)
        model_association.class_name = options.dig(:class_name)
        model_association.foreign_key = options.dig(:foreign_key)
        model_association.dependent = options.dig(:dependent)
        model_association.name_field = options.dig(:name_field)
        model_association
      end
    end

    def model_association(association_name)
      model_associations&.find { |ma| ma.kind == 'belongs_to' && ma.association_name == association_name }
    end

    def model_association_class_name(association_name)
      model_association = model_association(association_name)
      model_association&.class_name.presence || association_name.singularize.camelize
    end

    def model_association_name_field(association_name)
      model_association = model_association(association_name)
      model_association&.name_field.presence ||
        model_association&.foreign_key.presence ||
        "#{association_name.singularize}_id"
    end

    def model_association_search_path(association_name)
      "admin_#{association_name.pluralize}_path"
    end

    FormAssociation = Struct.new( :field )
    def form_associations
      model_association_names = model_associations&.map do |ma|
        %w(has_many has_one).include?(ma.kind) ? ma.association_name : nil
      end&.compact
      app.dig(:form, :fields)&.map do |form_field|
        field = hash_key_or_string(form_field)
        FormAssociation.new(field) if model_association_names.include?(field)
      end&.compact
    end

    ActiveStorage = Struct.new( :field, :kind, :thumb )
    ActiveStorageThumb = Struct.new( :kind, :width, :height )
    def active_storages
      model.dig(:active_storage)&.map do |field, options|
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
    def enums
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

    def enum?(field)
      enums&.find{ |enum| enum.field == field }
    end

    Decorator = Struct.new( :field, :append, :prepend, :digit )
    def decorators
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