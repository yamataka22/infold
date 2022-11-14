module Admin
  class BaseSearchForm
    include ActiveModel::Model

    attr_accessor :sort_field
    attr_writer :sort_kind

    class << self
      def conditions=(value)
        @conditions = value
      end

      def conditions
        @conditions || []
      end
    end

    def self.set_condition(*condition_names)
      attr_accessor *condition_names

      self.conditions += condition_names
    end

    def apply_conditions(records, page, limit, csv)
      if csv
        records = records.limit(1000)
      else
        limit ||= 50
        limit = 200 if limit > 200
        records = records.page(page).per(limit)
      end
      records = self.class.conditions.select{ |c| send(c).present? }.inject(records) do |_records, cond|
        _records.send(cond, send(cond))
      end
      records
    end

    def apply_sort(records, primary_key)
      records = records.order(sort_field => sort_kind) if sort_field.present?
      records = records.order(primary_key.to_sym) unless sort_kind.to_s == primary_key.to_s
      records
    end

    def sort_kind
      @sort_kind.to_s.downcase == 'asc' ? 'asc' : 'desc'
    end
  end
end