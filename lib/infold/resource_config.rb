require 'hashie'

module Infold
  class ResourceConfig
    attr_reader :setting

    def initialize(resource_name)
      @setting = Hashie::Mash.load(Rails.root.join("infold/#{resource_name}.yml"))
    end

    def form_associations
      return @form_associations if @form_associations
      model_has_many = @setting.model&.associations&.has_many.map{ |k,v| value_or_mash_key(k) }
      puts model_has_many.class.name
      form_fields = @setting.app&.form&.fields&.map{ |k,v| value_or_mash_key(k) }
      @form_associations = form_fields&.select { |name| puts "#{model_has_many} ... #{name}"; model_has_many.include?(name)  }
    end

    private

      # MashのキーまたはStringを返す
      def value_or_mash_key(val)
        val.is_a?(Hashie::Mash) ? val.keys[0] : val
      end
  end
end