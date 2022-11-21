require 'infold/field'

module Infold
  class FieldGroup
    include Enumerable

    attr_reader :fields

    def initialize(table=nil)
      init_fields(table)
    end

    def each
      @fields.each { |field| yield field }
    end

    def find_or_initialize_field(field_name)
      find { |field| field.name == field_name || field.association&.name == field_name } ||
        (@fields << Field.new(field_name)).last
    end

    def add_field(name, type=nil)
      (@fields << Field.new(name, type&.to_sym)).last
    end

    def datetime_fields
      select{ |f| f.type.to_s == 'datetime' && !%w(created_at updated_at).include?(f.name) }
    end

    def association_fields
      select { |f| f.association.present? }
    end

    def associations
      association_fields.map(&:association)
    end

    def active_storage_fields
      select { |f| f.active_storage.present? }
    end

    def validation_fields
      select { |f| f.validation.present? }
    end

    def enum_fields
      select { |f| f.enum.present? }
    end

    def decorator_fields
      decorator_fields = select { |f| f.decorator.present? }.to_a
      decorator_fields + select { |field| %i(datetime date boolean).include?(field.type) }&.each do |field|
        field.build_decorator(kind: field.type.to_sym)
      end.to_a
    end

    def condition_fields(kind=nil)
      case kind.to_s
      when 'index'
        select { |f| f.search_conditions.find(&:in_index?).present? }
      when 'association_search'
        select { |f| f.search_conditions.find(&:in_association_search?).present? }
      else
        select { |f| f.search_conditions.present? }
      end
    end

    def conditions(kind=nil)
      condition_fields(kind).map(&:search_conditions).flatten
    end

    def form_fields
      select { |f| f.form_element.present? }.sort_by { |f| f.form_element.seq }
    end

    def index_list_fields
      select { |f| f.in_index_list? }
    end

    def show_fields
      select { |f| f.show_element.present? }
    end

    def association_search_list_fields
      select { |f| f.in_association_search_list? }
    end

    private

    def init_fields(table)
      @fields = Array(table&.columns&.map { |column| Field.new(column.name, column.type&.to_sym) })
    end
  end
end