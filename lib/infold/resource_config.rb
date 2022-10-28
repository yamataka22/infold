module Infold
  class ResourceConfig
    attr_reader :resource_name,
                :setting

    def initialize(resource_name, setting)
      @resource_name = resource_name
      @setting = setting
    end

    def model_associations
      return @model_associations if @model_associations
      @model_associations = []
      @setting.model&.associations&.each do |association_kind, associations|
        @model_associations += associations&.map do |name, options|
          {
            kind: association_kind,
            name: name,
            options: options
          }
        end.to_a
      end
      @model_associations
    end

    def form_associations
      return @form_associations if @form_associations
      @form_associations = []
      form_fields = @setting.app&.form&.fields&.map{ |k,v| value_or_mash_key(k) }
      model_has_many = @setting.model&.associations&.has_many&.map{ |k,v| value_or_mash_key(k) }
      @form_associations += form_fields&.select { |name| model_has_many.include?(name)  }.to_a if model_has_many
      model_has_one = @setting.model&.associations&.has_one&.map{ |k,v| value_or_mash_key(k) }
      @form_associations += form_fields&.select { |name| model_has_one.include?(name)  }.to_a if model_has_one
      @form_associations
    end

    def active_storages

    end

    private

      # MashのキーまたはStringを返す
      def value_or_mash_key(val)
        val.is_a?(Hashie::Mash) ? val.keys[0] : val
      end
  end
end