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

  def add_columns(name, type)
    self.columns << Column.new(name, type)
  end

  def datetime_columns
    _columns = columns.select{ |c| c.type == 'datetime' && !%w(created_at updated_at).include?(c.name) }
    _columns.map(&:name)
  end
end