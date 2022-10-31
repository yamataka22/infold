module Infold
  class AppConfig
    attr_reader :resource_name,
                :model,
                :app

    def initialize(resource_name, setting)
      @resource_name = resource_name
      @model = setting.model
      @app = setting.app
    end

    def app_title
      app&.title
    end

    IndexCondition = Struct.new( :field, :sign )
    def index_conditions
      conditions = app&.index&.conditions&.map do |field, sign|
        if sign.is_a?(Hashie::Array)
          sign.map{ |s| IndexCondition.new( field, s ) }
        else
          IndexCondition.new( field, sign )
        end
      end
      conditions&.flatten
    end

    AssociationSearchCondition = Struct.new( :field, :sign )
    def association_search_conditions
      conditions = app&.association_search&.conditions&.map do |field, sign|
        if sign.is_a?(Hashie::Array)
          sign.map{ |s| AssociationSearchCondition.new( field, s ) }
        else
          AssociationSearchCondition.new( field, sign )
        end
      end
      conditions&.flatten
    end

    FormField = Struct.new( :field, :kind, :association_fields )
    def form_fields
      app&.form&.fields&.map do |field|
        form_field = FormField.new
        if field.is_a?(String)
          form_field.field = field
        else #Mash
          form_field.field = field.keys[0]
          options = field.values[0]
          form_field.kind = options&.kind
          if form_field.kind == 'associations'
            form_field.association_fields =
              options&.fields&.map do |association_field|
                association_form_field = FormField.new
                if association_field.is_a?(String)
                  association_form_field.field = association_field
                else #Mash
                  association_form_field.field = association_field.keys[0]
                  association_form_field.kind = association_field.values[0]&.kind
                end
                association_form_field
              end
          end
        end
        form_field
      end
    end
  end
end