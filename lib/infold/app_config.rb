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
  end
end