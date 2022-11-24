require 'forwardable'

module Infold
  class Association
    include ActiveModel::Model
    extend Forwardable

    attr_reader :field,
                :kind,
                :name,
                :table,
                :field_group

    attr_writer :name_field

    attr_accessor :class_name,
                  :foreign_key,
                  :dependent

    # [TODO] resourceとの共通化（associationはresourceである）
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
    delegate show_fields: :@field_group
    delegate association_search_list_fields: :@field_group

    def initialize(field, kind:, table:, field_group: [], name: nil, **attrs)
      @field = field
      @kind = kind
      @table = table
      @field_group = field_group
      @name = name || field.name
      super(**attrs)
    end

    def belongs_to?
      kind.to_sym == :belongs_to
    end

    def has_many?
      kind.to_sym == :has_many
    end

    def has_one?
      kind.to_sym == :has_one
    end

    def model_name(*attr)
      name = class_name.presence || self.name.singularize.camelize
      name = name.underscore if attr.include?(:snake)
      name = name.camelize if attr.include?(:camel)
      name = name.singularize if attr.include?(:single)
      name = name.pluralize if attr.include?(:multi)
      name
    end

    def find_or_initialize_field(field_name)
      field_group.find_or_initialize_field(field_name)
    end

    def search_path
      "admin_#{model_name(:multi, :snake)}_path"
    end

    def belongs_to_show_path(object)
      "admin_#{model_name( :snake)}_path(#{object})"
    end

    def name_field
      @name_field.presence || 'id'
    end
  end
end