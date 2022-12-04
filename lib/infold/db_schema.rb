require 'infold/table'

module Infold
  class DbSchema

    def initialize(content=nil)
      @tables = []
      return unless content
      content.split("\n").each.each do |row|
        row = row.strip
        if row.start_with?('create_table')
          table_name = row.split('"').second.strip
          table = Table.new(table_name)
          @tables << table
          table.add_columns('id', 'bigint') unless row.include?('id: false')
        elsif @tables.present? && row.start_with?('t.')
          table = @tables.last
          name = row.split('"').second.strip
          type = row.match(/^t\..*? /).to_s.gsub('t.', '').strip
          table.add_columns(name, type)
        end
      end
    end

    def table(name)
      @tables.find { |t| t.name.underscore.singularize == name.underscore.singularize }
    end
  end
end