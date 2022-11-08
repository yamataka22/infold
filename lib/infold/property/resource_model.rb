require "active_support/core_ext/hash/indifferent_access"

module Infold
  module ResourceModel

    def association_fields
      fields.select { |f| f.association.present? }
    end

    def associations
      association_fields.map(&:association)
    end

    def active_storage_fields
      fields.select { |f| f.active_storage.present? }
    end

    def validation_fields
      fields.select { |f| f.validation.present? }
    end

    def enum_fields
      fields.select { |f| f.enum.present? }
    end

    def decorator_fields
      fields.select { |f| f.decorator.present? }
    end

    private

    def set_associations
      model.dig(:association)&.each do |field_name, options|
        kind = options.dig(:kind)
        foreign_key = options.dig(:foreign_key).presence
        class_name = options.dig(:class_name).presence
        if kind == 'belongs_to'
          foreign_key ||= "#{class_name.underscore}_id" if class_name
          foreign_key ||= "#{field_name.underscore}_id"
          field = find_or_initialize_field(foreign_key)
        else
          field = find_or_initialize_field(field_name)
        end
        field.build_association(
          kind: kind,
          association_name: field_name,
          class_name: class_name,
          foreign_key: foreign_key,
          dependent: options.dig(:dependent),
          name_field: options.dig(:name_field),
          db_schema: @db_schema
        )
      end
    end

    def set_active_storages
      model.dig(:active_storage)&.each do |field_name, options|
        field = find_or_initialize_field(field_name)
        active_storage = field.build_active_storage(kind: options&.dig(:kind))
        thumb = options.dig(:thumb)
        if active_storage.kind_image? && thumb.present?
          active_storage.build_thumb(
            kind: thumb.dig(:kind),
            width: thumb.dig(:width),
            height: thumb.dig(:height))
        end
      end
    end

    def set_validations
      model.dig(:validate)&.each do |field_name, condition|
        field = find_or_initialize_field(field_name)
        validation = field.build_validation
        if condition.is_a?(String)
          validation.add_conditions(condition: condition)
        elsif condition.is_a?(Array)
          condition.each do |_condition|
            if _condition.is_a?(String)
              validation.add_conditions(condition: _condition)
            else
              validation.add_conditions(condition: _condition.keys[0], options: _condition[_condition.keys[0]])
            end
          end
        end
      end
    end

    def set_enums
      model.dig(:enum)&.each do |field_name, elements|
        field = find_or_initialize_field(field_name)
        enum = field.build_enum
        elements.each do |key, options|
          element = enum.add_elements(key: key)
          if options.is_a?(Hash)
            element.value = options.dig(:value)
            element.color = options.dig(:color)
          else
            element.value = options
          end
        end
      end
    end

    def set_decorators
      model.dig(:decorator)&.each do |field_name, options|
        field = find_or_initialize_field(field_name)
        field.build_decorator(
          kind: %i(integer float decimal).include?(field.type) ? :number : :string,
          append: options.dig(:append),
          prepend: options.dig(:prepend),
          digit: options.dig(:digit)
        )
      end
      fields.select { |field| %i(datetime date boolean).include?(field.type) }&.each do |field|
        field.build_decorator(kind: field.type.to_sym)
      end
      model.dig(:enum)&.each do |field_name, elements|
        field = find_or_initialize_field(field_name)
        field.build_decorator(kind: :enum)
      end
    end
  end
end