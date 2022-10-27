module Infold
  class DbSchema
    attr_reader :table

    def self.read_schema(target)
      table = contents = nil
      target = target.underscore.singularize
      File.open(Rails.root.join('db/schema.rb'), "r") { |file| contents = file.read.to_s }
      contents&.split("\n").each.each do |row|
        row = row.strip
        if row.start_with?('create_table')
          table_name = row.split('"').second.strip
          next unless target == table_name.underscore.singularize
          table = Table.new(table_name)
        elsif table && row.start_with?('t.')
          name = row.split('"').first.strip
          type = row.match(/^t\..*? /).to_s.gsub('t.', '').strip
          table.add_column(name, type)
        end
      end
      table
    end
  end
end