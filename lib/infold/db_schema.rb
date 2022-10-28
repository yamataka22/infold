module Infold
  class DbSchema
    attr_reader :tables

    def initialize
      @tables = []
      contents = nil
      File.open(Rails.root.join('db/schema.rb'), "r") { |file| contents = file.read.to_s }
      contents&.split("\n").each.each do |row|
        row = row.strip
        if row.start_with?('create_table')
          table_name = row.split('"').second.strip
          @tables << Table.new(table_name)
        elsif @tables.present? && row.start_with?('t.')
          table = @tables.last
          name = row.split('"').second.strip
          type = row.match(/^t\..*? /).to_s.gsub('t.', '').strip
          table.add_columns(name, type)
        end
      end
    end

    def table(target)
      target = target.underscore.singularize
      tables.find { |t| t.name.underscore.singularize == target }
    end

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
  end
end