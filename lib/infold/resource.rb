module Infold
  class Resource

    attr_reader :name,
                :fields

    def initialize(name, fields)
      @name = name
      @fields = fields
    end

    def datetime_fields
      fields.select{ |f| f.type.to_s == 'datetime' && !%w(created_at updated_at).include?(f.name) }
    end

    def association_fields
      fields.select { |f| f.association.present? }
    end

    def associations
      association_fields.map(&:association)
    end

    def active_storage_fields
      fields.select { |f| f.active_storage.present? }
    end

    def validation_fields
      fields.select { |f| f.validation.present? }
    end

    def enum_fields
      fields.select { |f| f.enum.present? }
    end

    def decorator_fields
      decorator_fields = @fields.select { |f| f.decorator.present? }.to_a
      decorator_fields + @fields.select { |field| %i(datetime date boolean).include?(field.type) }&.each do |field|
        field.build_decorator(kind: field.type.to_sym)
      end.to_a
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
  end
end