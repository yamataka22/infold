require "active_support/core_ext/hash/indifferent_access"

module Infold
  class AppConfig
    attr_reader :resource_name,
                :model,
                :app

    def initialize(resource_name, yaml)
      @resource_name = resource_name
      @model = yaml.dig('model').to_h.with_indifferent_access
      @app = yaml.dig('app').to_h.with_indifferent_access
    end

    def app_title
      app.dig(:title)
    end

    Condition = Struct.new( :field, :sign )
    def index_conditions
      app.dig(:index, :conditions)&.map do |condition|
        Condition.new( condition.keys[0], condition[condition.keys[0]] )
      end
    end

    def association_search_conditions
      app.dig(:association_search, :conditions)&.map do |condition|
        Condition.new( condition.keys[0], condition[condition.keys[0]] )
      end
    end

    def search_conditions
      (index_conditions.to_a + association_search_conditions.to_a).uniq
    end

    FormField = Struct.new( :field, :kind, :association_fields )
    def form_fields
      app.dig(:form, :fields)&.map do |field_config|
        if field_config.is_a?(String)
          form_field = FormField.new(field_config)
        else
          field = field_config.keys[0]
          form_field = FormField.new(field, field_config[field].dig(:kind), [])
          if form_field.kind == 'association'
            field_config[field].dig(:fields)&.each do |association_field_config|
              if association_field_config.is_a?(String)
                form_field.association_fields << FormField.new(association_field_config)
              else
                association_field = association_field_config.keys[0]
                form_field.association_fields <<
                  FormField.new(association_field, association_field_config[association_field].dig(:kind))
              end
            end
          end
        end
        form_field
      end
    end
  end
end