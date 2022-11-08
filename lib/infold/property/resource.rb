require "active_support/core_ext/hash/indifferent_access"
require 'infold/property/resource_model'
require 'infold/property/resource_app'
require 'infold/property/field'
require 'infold/db_schema'

module Infold
  class Resource
    include ResourceModel
    include ResourceApp

    attr_reader :name,
                :table,
                :fields
    attr_accessor :index_default_order,
                  :association_search_default_order

    def initialize(name, resource_yaml, db_schema=nil)
      @name = name
      @resource_yaml = resource_yaml.with_indifferent_access
      @db_schema = db_schema || DbSchema.new(File.read(Rails.root.join('db/schema.rb')))
      @table = @db_schema.find_table(name)
      @fields = @table.columns.map { |column| Field.new(column.name, column.type&.to_sym) }
      set_associations
      set_active_storages
      set_validations
      set_enums
      set_decorators
      set_search_conditions
      set_list_fields
      set_form_elements
      set_default_order
    end

    def model
      @resource_yaml.dig('model') || {}
    end

    def app
      @resource_yaml.dig('app') || {}
    end

    def find_or_initialize_field(field_name, type=nil)
      find_field(field_name) || (@fields << Field.new(field_name, type)).last
    end

    def find_field(field_name)
      @fields.find { |field| field.name == field_name }
    end

    def find_association(association_name)
      associations.find { |association| association.association_name == association_name }
    end
  end
end