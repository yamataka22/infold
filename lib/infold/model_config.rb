module Infold
  # resource.ymlをhashに展開する役割
  class ModelConfig
    attr_reader :resource_name,
                :model,
                :app

    def initialize(resource_name, setting)
      @resource_name = resource_name
      @model = setting.model
      @app = setting.app
    end

    ModelAssociation = Struct.new( :kind, :field, :options )
    def model_associations
      model&.associations&.map do |association_kind, associations|
        associations&.map do |name, options|
          ModelAssociation.new(association_kind, name, options&.to_h)
        end
      end&.compact&.flatten
    end

    FormAssociation = Struct.new( :field )
    def form_associations
      model_associations =
        element_values(model&.associations&.has_many) + element_values(model&.associations&.has_one)
      element_values(app&.form&.fields).map do |form_field|
        FormAssociation.new(form_field) if model_associations.include?(form_field)
      end&.compact
    end

    ActiveStorage = Struct.new( :field, :kind, :thumb )
    ActiveStorageThumb = Struct.new( :kind, :width, :height )
    def active_storages
      model&.active_storage&.map do |field, options|
        kind = options&.kind || 'file'
        thumb = nil
        if kind == 'image' && options&.thumb.present?
          thumb = ActiveStorageThumb.new(options.thumb.kind.presence || 'fit',
                                         options.thumb.width.presence || '400',
                                         options.thumb.height.presence || '400')
        end
        ActiveStorage.new(field, kind, thumb)
      end
    end

    Validate = Struct.new( :field, :conditions )
    ValidateCondition = Struct.new( :condition, :options )
    def validates
      model&.validates&.map do |field, conditions|
        validate = Validate.new
        validate.field = field
        if conditions.is_a?(Hashie::Array)
          validate.conditions = conditions.map do |condition|
            if condition.is_a?(Hashie::Mash)
              ValidateCondition.new(condition.keys[0], condition.values[0])
            else
              ValidateCondition.new(condition)
            end
          end
        elsif conditions.is_a?(Hashie::Mash)
          validate.conditions = [ ValidateCondition.new(conditions.keys[0], conditions.values[0]) ]
        else
          validate.conditions = [ ValidateCondition.new(conditions) ]
        end
        validate
      end
    end

    Enum = Struct.new( :field, :elements )
    EnumElement = Struct.new( :key, :value, :color )
    def enum
      model&.enum&.map do |field, elements|
        enum = Enum.new
        enum.field = field
        enum.elements = elements.map do |key, options|
          element = EnumElement.new
          element.key = key
          if options.is_a?(Hashie::Mash)
            element.value = options.value
            element.color = options.color
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
      model&.decorates&.map do |field, options|
        decorator = Decorator.new
        decorator.field = field
        decorator.append = options.append
        decorator.prepend = options.prepend
        decorator.digit = options.digit
        decorator
      end
    end

    private

      # Mashの直下のキー郡または配列を返す
      def element_values(element)
        if element.is_a?(Hashie::Mash)
          element.keys
        elsif element.is_a?(Hashie::Array)
          element.map { |e| e.is_a?(Hashie::Mash) ? e.keys[0] : e }
        else
          element
        end.to_a
      end
  end
end