require "active_support/core_ext/hash/indifferent_access"
require 'infold/property/default_order'

module Infold
  module ResourceApp

    def app_title
      app.dig(:title)
    end

    def condition_fields(kind=nil)
      case kind.to_s
      when 'index'
        fields.select { |f| f.search_conditions.find(&:in_index?).present? }
      when 'association_search'
        fields.select { |f| f.search_conditions.find(&:in_association_search?).present? }
      else
        fields.select { |f| f.search_conditions.present? }
      end
    end

    def conditions
      condition_fields.map(&:search_conditions)&.flatten
    end

    def form_element_fields
      fields.select { |f| f.form_element.present? }
    end

    def index_list_fields
      fields.select { |f| f.in_index_list? }
    end

    def association_search_list_fields
      fields.select { |f| f.in_association_search_list? }
    end

    private

    def set_search_conditions
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
    end

    def set_default_order
      default_order = app.dig(:index, :list, :default_order)
      if default_order&.dig(:field)
        field = find_or_initialize_field(default_order.dig(:field))
        self.index_default_order =
          DefaultOrder.new(self, field, default_order.dig(:kind))
      end

      default_order = app.dig(:association_search, :list, :default_order)
      if default_order&.dig(:field)
        field = find_or_initialize_field(default_order.dig(:field))
        self.association_search_default_order =
          DefaultOrder.new(self, field, default_order.dig(:kind))
      end
    end

    def set_list_fields
      field_names = app.dig(:index, :list, :fields).presence
      field_names ||= table.columns[0, 5].map(&:name)
      field_names.each do |field_name|
        field = find_or_initialize_field(field_name)
        field.in_index_list = true
      end

      field_names = app.dig(:association_search, :list, :fields).presence
      field_names ||= table.columns[0, 2].map(&:name)
      field_names.map do |field_name|
        field = find_or_initialize_field(field_name)
        field.in_association_search_list = true
      end
    end

    def set_form_elements
      app.dig(:form, :fields)&.each do |field_config|
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
                association_field = association.find_or_initialize_association_field(association_field_config)
                association_field.build_form_element
              else
                association_field = association.find_or_initialize_association_field(association_field_config.keys[0])
                association_field.build_form_element(form_kind: association_field_config[association_field.name].dig(:kind))
              end
              form_element.add_association_fields(association_field)
            end
          end
        end
      end
    end
  end
end