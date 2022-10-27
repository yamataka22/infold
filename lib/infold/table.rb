module Infold
  class Table

    attr_accessor :name,
                  :columns

    Column = Struct.new(:name, :type)

    def initialize(name)
      self.name = name
      self.columns = []
    end

    def model_name
      name.singularize.camelize
    end

    def add_column(name, type)
      self.columns << Column.new(name, type)
    end

    def has_datetime_column?
      self.columns.select { |c| !%w(created_at updated_at).include?(c.name) && c.type == 'datetime' }.present?
    end
  end
end