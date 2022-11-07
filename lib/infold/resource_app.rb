require "active_support/core_ext/hash/indifferent_access"

module Infold
  module ResourceApp

    def app_title
      app.dig(:title)
    end

    Condition = Struct.new( :field, :sign, :form_kind, :association_name )
    def index_conditions
      app.dig(:index, :conditions)&.map do |condition|
        field = condition.keys[0]
        Condition.new( field,
                       condition.dig(field, :sign),
                       condition.dig(field, :form_kind),
                       condition.dig(field, :association_name))
      end
    end

    def association_search_conditions
      app.dig(:association_search, :conditions)&.map do |condition|
        field = condition.keys[0]
        Condition.new( field,
                       condition.dig(field, :sign),
                       condition.dig(field, :form_kind),
                       condition.dig(field, :association_name))
      end
    end

    def search_conditions
      (index_conditions.to_a + association_search_conditions.to_a).uniq
    end

    DefaultOrder = Struct.new( :field, :kind )
    def index_default_order
      default_order = app.dig(:index, :list, :default_order)
      if default_order&.dig(:field)
        DefaultOrder.new(default_order.dig(:field),
                         default_order.dig(:kind))
      end
    end

    def association_search_default_order
      default_order = app.dig(:association_search, :list, :default_order)
      if default_order&.dig(:field)
        DefaultOrder.new(default_order.dig(:field),
                         default_order.dig(:kind))
      end
    end

    ListField = Struct.new( :field, :type )
    def index_list_fields
      fields = app.dig(:index, :list, :fields)
      fields ||= self_table.columns[0, 5].map(&:name)
      fields.map { |f| ListField.new(f) }
      fields.map do |field|
        list_field = ListField.new(field)

      end
    end

    def association_search_list_fields
      fields = app.dig(:association_search, :list, :fields)
      fields ||= self_table.columns[0, 2].map(&:name)
      fields.map { |f| ListField.new(f) }
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