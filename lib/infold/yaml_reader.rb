require "active_support/core_ext/hash/indifferent_access"
require 'infold/resource'
require 'infold/field_group'
require 'infold/property/default_order'

module Infold
  class YamlReader
    class << self
      def generate_resource(resource_name, yaml, db_schema)
        @db_schema = db_schema
        field_group = FieldGroup.new(db_schema.table(resource_name))
        resource = Resource.new(resource_name)
        yaml = yaml.with_indifferent_access
        model = yaml.dig('model') || {}
        app = yaml.dig('app') || {}
        assign_associations(     field_group, model.dig(:association))
        assign_active_storages(  field_group, model.dig(:active_storage))
        assign_validations(      field_group, model.dig(:validate))
        assign_enums(            field_group, model.dig(:enum))
        assign_enum_decorators(  field_group, model.dig(:enum))
        assign_decorators(       field_group, model.dig(:decorator))
        assign_search_conditions(field_group, app)
        assign_list_fields(      field_group, app)
        assign_show_elements(    field_group, app)
        assign_form_elements(    field_group, app)
        resource.field_group = field_group
        default_order = app.dig(:index, :list, :default_order)
        if default_order&.dig(:field)
          field = field_group.find_or_initialize_field(default_order.dig(:field))
          resource.default_order = DefaultOrder.new(self, field, default_order.dig(:kind))
        end
        resource.app_title = app.dig(:title)
        resource
      end

      private

      def assign_associations(field_group, content)
        content&.each do |field_name, options|
          kind = options.dig(:kind)
          foreign_key = options.dig(:foreign_key).presence
          class_name = options.dig(:class_name).presence
          if kind == 'belongs_to'
            foreign_key ||= "#{class_name.underscore}_id" if class_name
            foreign_key ||= "#{field_name.underscore}_id"
            field = field_group.find_or_initialize_field(foreign_key)
          else
            field = field_group.find_or_initialize_field(field_name)
          end
          association_table = @db_schema.table(class_name || field_name)
          association_field_group = FieldGroup.new(association_table)
          # association先のmodelの情報
          association_model = options.dig(:model)
          if association_model
            association_field_group.has_association_model = true
            assign_associations(     association_field_group, association_model.dig(:association))
            assign_active_storages(  association_field_group, association_model.dig(:active_storage))
            assign_validations(      association_field_group, association_model.dig(:validate))
            assign_enums(            association_field_group, association_model.dig(:enum))
            assign_enum_decorators(  association_field_group, association_model.dig(:enum))
            assign_decorators(       association_field_group, association_model.dig(:decorator))
          end
          field.build_association(
            table: association_table,
            field_group: association_field_group,
            kind: kind,
            name: field_name,
            class_name: class_name,
            foreign_key: foreign_key,
            dependent: options.dig(:dependent),
            name_field: options.dig(:name_field)
          )
        end
      end

      def assign_active_storages(field_group, content)
        content&.each do |field_name, options|
          field = field_group.find_or_initialize_field(field_name)
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

      def assign_validations(field_group, content)
        content&.each do |field_name, condition|
          field = field_group.find_or_initialize_field(field_name)
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
        end
      end

      def assign_enums(field_group, content)
        content&.each do |field_name, elements|
          field = field_group.find_or_initialize_field(field_name)
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
        end
      end

      def assign_decorators(field_group, content)
        content&.each do |field_name, options|
          field = field_group.find_or_initialize_field(field_name)
          field.build_decorator(
            kind: %i(integer float decimal).include?(field.type) ? :number : :string,
            append: options.dig(:append),
            prepend: options.dig(:prepend),
            digit: options.dig(:digit)
          )
        end
      end

      def assign_enum_decorators(field_group, content)
        content&.each do |field_name, elements|
          field = field_group.find_or_initialize_field(field_name)
          field.build_decorator(kind: :enum)
        end
      end

      def assign_search_conditions(field_group, app)
        app.dig(:index, :conditions)&.each_with_index do |condition, seq|
          field = field_group.find_or_initialize_field(condition.keys[0])
          cond = condition.dig(condition.keys[0])
          field.add_search_condition(:index,
                                     sign: cond.dig(:sign),
                                     form_kind: cond.dig(:form_kind),
                                     seq: seq,
                                     association_name: cond.dig(:association_name))
        end
        app.dig(:association_search, :conditions)&.each_with_index do |condition, seq|
          field = field_group.find_or_initialize_field(condition.keys[0])
          cond = condition.dig(condition.keys[0])
          field.add_search_condition(:association_search,
                                     sign: cond.dig(:sign),
                                     seq: seq,
                                     form_kind: cond.dig(:form_kind))
        end
      end

      def assign_list_fields(field_group, app)
        field_names = app.dig(:index, :list, :fields).presence
        field_names ||= field_group.fields[0, 5]&.map(&:name)
        field_names.each_with_index do |field_name, seq|
          field = field_group.find_or_initialize_field(field_name)
          field.index_list_seq = seq
        end

        field_names = app.dig(:association_search, :list, :fields).presence
        field_names ||= field_group.fields[0, 2]&.map(&:name)
        field_names.each_with_index do |field_name, seq|
          field = field_group.find_or_initialize_field(field_name)
          field.association_search_list_seq = seq
        end
      end

      def assign_show_elements(field_group, app)
        field_configs = app.dig(:show, :fields).presence
        field_configs ||= field_group.map(&:name)
        field_configs.each_with_index do |field_config, seq|
          if field_config.is_a?(String)
            field = field_group.find_or_initialize_field(field_config)
            field.build_show_element(seq: seq)
          else
            field = field_group.find_or_initialize_field(field_config.keys[0])
            show_element = field.build_show_element(seq: seq)
            if show_element.kind_association?
              association = find_association(field_group, show_element.field.name)
              field_config[field.name].dig(:fields)&.each_with_index do |association_field_name, association_seq|
                association_field =
                  association.find_or_initialize_field(association_field_name)
                show_element.add_association_fields(association_field, seq: association_seq)
              end
            end
          end
        end
      end

      def assign_form_elements(field_group, app)
        app.dig(:form, :fields)&.each_with_index do |field_config, seq|
          if field_config.is_a?(String)
            field = field_group.find_or_initialize_field(field_config)
            field.build_form_element(seq: seq)
          else
            field = field_group.find_or_initialize_field(field_config.keys[0])
            form_element = field.build_form_element(form_kind: field_config[field.name].dig(:kind), seq: seq)
            if form_element.kind_has_association?
              association = find_association(field_group, form_element.field.name)
              field_config[field.name].dig(:fields)&.each_with_index do |association_field_config, association_seq|
                if association_field_config.is_a?(String)
                  association_field =
                    association.find_or_initialize_field(association_field_config)
                  form_element.add_association_fields(association_field, seq: association_seq)
                else
                  association_field =
                    association.find_or_initialize_field(association_field_config.keys[0])
                  form_element.add_association_fields(
                    association_field,
                    seq: association_seq,
                    form_kind: association_field_config.dig(association_field.name, :kind))
                end
              end
            end
          end
        end
      end

      def find_association(field_group, association_name)
        if field_group.associations
          field_group.associations.find{ |association| association.name == association_name }
        else
          raise "no associations"
        end
      end
    end
  end
end