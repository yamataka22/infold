require 'forwardable'

module Infold
  class Resource
    extend Forwardable

    attr_reader :name

    attr_accessor :app_title,
                  :field_group,
                  :default_order

    def initialize(name)
      @name = name
    end

    delegate association_fields: :@field_group
    delegate associations: :@field_group
    delegate active_storage_fields: :@field_group
    delegate validation_fields: :@field_group
    delegate datetime_fields: :@field_group
    delegate enum_fields: :@field_group
    delegate decorator_fields: :@field_group
    delegate condition_fields: :@field_group
    delegate conditions: :@field_group
    delegate form_fields: :@field_group
    delegate index_list_fields: :@field_group
    delegate csv_fields: :@field_group
    delegate show_fields: :@field_group
    delegate association_search_list_fields: :@field_group
  end
end