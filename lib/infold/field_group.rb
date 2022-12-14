require 'infold/field'

module Infold
  class FieldGroup
    include Enumerable

    attr_reader :fields
    attr_writer :has_association_model

    def initialize(table=nil)
      init_fields(table)
    end

    def each
      @fields.each { |field| yield field }
    end

    def find_or_initialize_field(field_name)
      find { |field| field.association&.name == field_name || field.name == field_name } ||
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
      decorator_fields + select { |field| %i(datetime date boolean).include?(field.type) }.each do |field|
        field.build_decorator(kind: field.type.to_sym)
      end.to_a
    end

    def condition_fields(kind=nil)
      fields =
        case kind.to_s
        when 'index'
          select { |f| f.search_conditions.find(&:in_index?).present? }
        when 'association_search'
          select { |f| f.search_conditions.find(&:in_association_search?).present? }
        else
          select { |f| f.search_conditions.present? }
        end
      if fields.blank?
        # 条件が未設定の場合、idを対象とする
        id_field = find_or_initialize_field(:id)
        id_field.add_search_condition(kind || :index,
                                      sign: 'eq',
                                      form_kind: :text)
        fields = [id_field]
      end
      fields
    end

    def conditions(kind=nil)
      conditions = condition_fields(kind).map(&:search_conditions).flatten
      if kind.to_s == 'index'
        conditions.sort_by(&:index_seq)
      elsif kind.to_s == 'association_search'
        conditions.sort_by(&:association_seq)
      else
        conditions
      end
    end

    def form_fields
      select { |f| f.form_element.present? }.sort_by { |f| f.form_element.seq }
    end

    def index_list_fields
      select { |f| f.in_index_list? }.sort_by { |f| f.index_list_seq }
    end

    def csv_fields
      select { |f| f.in_csv? }.sort_by { |f| f.csv_seq }
    end

    def show_fields
      select { |f| f.show_element.present? }.sort_by { |f| f.show_element.seq }
    end

    def association_search_list_fields
      select { |f| f.in_association_search_list? }.sort_by { |f| f.association_search_list_seq }
    end

    def has_association_model?; @has_association_model end

    private

    def init_fields(table)
      @fields = Array(table&.columns&.map { |column| Field.new(column.name, column.type&.to_sym) })
    end
  end
end