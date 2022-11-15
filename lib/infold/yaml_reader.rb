require "active_support/core_ext/hash/indifferent_access"
require 'infold/field'
require 'infold/property/default_order'

module Infold
  class YamlReader

    def initialize(resource_name, yaml, db_schema)
      @yaml = yaml.with_indifferent_access
      @db_schema = db_schema
      @table = @db_schema.table(resource_name)
      init_fields
    end

    def fields
      init_fields
      read_associations
      read_active_storages
      read_validations
      read_enums
      read_decorators
      read_search_conditions
      read_list_fields
      read_show_elements
      read_form_elements
      @fields
    end

    def default_order
      default_order = app.dig(:index, :list, :default_order)
      if default_order&.dig(:field)
        field = find_or_initialize_field(default_order.dig(:field))
        DefaultOrder.new(self, field, default_order.dig(:kind))
      end
    end

    def app_title
      app.dig(:title)
    end

    private

    def model
      @yaml.dig('model') || {}
    end

    def app
      @yaml.dig('app') || {}
    end

    def init_fields
      @fields = @table.columns.map { |column| Field.new(column.name, column.type&.to_sym) }
    end

    def find_or_initialize_field(field_name, type=nil)
      find_field(field_name) || (@fields << Field.new(field_name, type)).last
    end

    def find_field(field_name)
      @fields.find { |field| field.name == field_name }
    end

    def find_association(association_name)
      read_associations.find { |association| association.name == association_name }
    end

    def read_associations
      return @associations if @associations
      @associations = []
      model.dig(:association)&.each do |field_name, options|
        kind = options.dig(:kind)
        foreign_key = options.dig(:foreign_key).presence
        class_name = options.dig(:class_name).presence
        if kind == 'belongs_to'
          foreign_key ||= "#{class_name.underscore}_id" if class_name
          foreign_key ||= "#{field_name.underscore}_id"
          field = find_or_initialize_field(foreign_key)
        else
          field = find_or_initialize_field(field_name)
        end
        @associations << field.build_association(
          association_table: @db_schema.table(field_name.pluralize),
          kind: kind,
          name: field_name,
          class_name: class_name,
          foreign_key: foreign_key,
          dependent: options.dig(:dependent),
          name_field: options.dig(:name_field)
        )
      end
      @associations
    end

    def read_active_storages
      model.dig(:active_storage)&.map do |field_name, options|
        field = find_or_initialize_field(field_name)
        active_storage = field.build_active_storage(kind: options&.dig(:kind))
        thumb = options.dig(:thumb)
        if active_storage.kind_image? && thumb.present?
          active_storage.build_thumb(
            kind: thumb.dig(:kind),
            width: thumb.dig(:width),
            height: thumb.dig(:height))
        end
        active_storage
      end
    end

    def read_validations
      model.dig(:validate)&.map do |field_name, condition|
        field = find_or_initialize_field(field_name)
        if condition.is_a?(String)
          field.add_validation(condition)
        elsif condition.is_a?(Array)
          condition.each do |_condition|
            if _condition.is_a?(String)
              field.add_validation(_condition)
            else
              field.add_validation(_condition.keys[0],
                                   _condition[_condition.keys[0]])
            end
          end
        end
        field.validation
      end
    end

    def read_enums
      model.dig(:enum)&.map do |field_name, elements|
        field = find_or_initialize_field(field_name)
        enum = field.build_enum
        elements.each do |key, options|
          element = enum.add_elements(key: key)
          if options.is_a?(Hash)
            element.value = options.dig(:value)
            element.color = options.dig(:color)
          else
            element.value = options
          end
        end
        enum
      end
    end

    def read_decorators
      decorators = []
      model.dig(:decorator)&.each do |field_name, options|
        field = find_or_initialize_field(field_name)
        decorators << field.build_decorator(
          kind: %i(integer float decimal).include?(field.type) ? :number : :string,
          append: options.dig(:append),
          prepend: options.dig(:prepend),
          digit: options.dig(:digit)
        )
      end
      model.dig(:enum)&.each do |field_name, elements|
        field = find_or_initialize_field(field_name)
        decorators << field.build_decorator(kind: :enum)
      end
      decorators
    end

    def read_search_conditions
      app.dig(:index, :conditions)&.each do |condition|
        field = find_or_initialize_field(condition.keys[0])
        cond = condition.dig(condition.keys[0])
        field.add_search_condition(:index,
                                   sign: cond.dig(:sign),
                                   form_kind: cond.dig(:form_kind),
                                   association_name: cond.dig(:association_name))
      end
      app.dig(:association_search, :conditions)&.each do |condition|
        field = find_or_initialize_field(condition.keys[0])
        cond = condition.dig(condition.keys[0])
        field.add_search_condition(:association_search,
                                   sign: cond.dig(:sign),
                                   form_kind: cond.dig(:form_kind))
      end
      @fields.select { |f| f.search_conditions.present? }&.map(&:search_conditions)&.flatten
    end

    def read_list_fields
      field_names = app.dig(:index, :list, :fields).presence
      field_names ||= @table.columns[0, 5].map(&:name)
      field_names.each do |field_name|
        field = find_or_initialize_field(field_name)
        field.in_index_list = true
      end

      field_names = app.dig(:association_search, :list, :fields).presence
      field_names ||= @table.columns[0, 2].map(&:name)
      field_names.map do |field_name|
        field = find_or_initialize_field(field_name)
        field.in_association_search_list = true
      end

      @fields.select { |f| f.in_index_list? || f.in_association_search_list? }
    end

    def read_show_elements
      field_configs = app.dig(:show, :fields).presence
      field_configs ||= @table.columns.map(&:name)
      field_configs.map do |field_config|
        if field_config.is_a?(String)
          field = find_or_initialize_field(field_config)
          field.build_show_element
        else
          field = find_or_initialize_field(field_config.keys[0])
          show_element = field.build_show_element
          if show_element.kind_association?
            association = find_association(show_element.field.name)
            field_config[field.name].dig(:fields)&.each do |association_field_name|
              association_field =
                association.find_or_initialize_association_field(association_field_name)
              show_element.add_association_fields(association_field)
            end
          end
          show_element
        end
      end
    end

    def read_form_elements
      app.dig(:form, :fields)&.map do |field_config|
        if field_config.is_a?(String)
          field = find_or_initialize_field(field_config)
          field.build_form_element
        else
          field = find_or_initialize_field(field_config.keys[0])
          form_element = field.build_form_element(form_kind: field_config[field.name].dig(:kind))
          if form_element.kind_association?
            association = find_association(form_element.field.name)
            field_config[field.name].dig(:fields)&.each do |association_field_config|
              if association_field_config.is_a?(String)
                association_field =
                  association.find_or_initialize_association_field(association_field_config)
                form_element.add_association_fields(association_field)
              else
                association_field =
                  association.find_or_initialize_association_field(association_field_config.keys[0])
                form_element.add_association_fields(
                  association_field,
                  form_kind: association_field_config.dig(association_field.name, :kind))
              end
            end
          end
          form_element
        end
      end
    end
  end
end