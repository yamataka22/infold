module Infold
  # resource.ymlをhashに展開する役割
  class ResourceConfig
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