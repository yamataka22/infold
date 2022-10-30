require 'infold/writers/base_writer'

module Infold
  class DecoratorWriter < BaseWriter
    def decorator_code
      code = self_table&.columns&.map do |column|
        enum = @model_config.enum&.find { |e| e.field == column.name }
        if enum
          enum_code(column.name, enum)
        else
          option = @model_config.decorator&.find { |d| d.field == column.name }
          case column.type
          when 'boolean'
            boolean_code(column.name)
          when 'datetime'
            datetime_code(column.name)
          when 'date'
            date_code(column.name)
          when 'integer', 'float', 'decimal'
            number_code(column.name, option.digit, option.append, option.prepend) if option
          else
            string_code(column.name, option.append, option.prepend) if option
          end
        end
      end
      inset_indent(code.compact.join("\n"), 2) if code.present?
    end

    private

      def boolean_code(field)
        <<-CODE.gsub(/^\s+/, '')
          def #{field}_display
          [TAB]'<i class="bi bi-check-square-fill text-info"></i>'.html_safe if #{field}?
          end
        CODE
      end

      def datetime_code(field)
        <<-CODE.gsub(/^\s+/, '')
          def #{field}_display
          [TAB]#{field} ? I18n.l(#{field}) : ''
          end
        CODE
      end

      def date_code(field)
        <<-CODE.gsub(/^\s+/, '')
          def #{field}_display
          [TAB]#{field} ? I18n.l(#{field}) : ''
          end
        CODE
      end

      def number_code(field, digit, append, prepend)
        code = digit ? "#{field}.to_formatted_s(:delimited)" : "#{field}.to_s"
        code = set_append_and_prepend(code, append, prepend) if append.present? || prepend.present?
        <<-CODE.gsub(/^\s+/, '')
          def #{field}_display
          [TAB]#{code} if #{field}.present?
          end
        CODE
      end

      def string_code(field, append, prepend)
        code = field
        code = set_append_and_prepend(code, append, prepend) if append.present? || prepend.present?
        <<-CODE.gsub(/^\s+/, '')
          def #{field}_display
          [TAB]#{code} if #{field}.present?
          end
        CODE
      end

      def set_append_and_prepend(code, append, prepend)
        "\"#{prepend}\#{#{code}}#{append}\""
      end

      def enum_code(field, enum)
        code = enum.elements.select{ |e| e.color.present? }.map do |e|
          "[TAB]when '#{e.key}' then '#{e.color}'"
        end
        return nil if code.blank?
        <<-CODE.gsub(/^\s+/, '')
          def #{field}_color
          [TAB]case #{field}.to_s
          #{code.join("\n")}
          [TAB]else ''
          [TAB]end
          end
        CODE
      end
  end
end