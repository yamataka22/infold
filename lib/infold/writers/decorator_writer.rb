require 'infold/writers/base_writer'

module Infold
  class DecoratorWriter < BaseWriter
    def decorator_code
      codes = @resource.decorator_fields&.map do |field|
        case field.decorator.kind
        when :enum
          enum_code(field).presence
        when :boolean
          boolean_code(field.name).presence
        when :datetime
          datetime_code(field.name).presence
        when :date
          date_code(field.name).presence
        when :number
          number_code(field.name, field.decorator).presence
        else
          string_code(field.name, field.decorator).presence
        end
      end
      indent(codes.compact.join("\n"), 2) if codes.present?
    end

    private

      def boolean_code(name)
        <<-CODE.gsub(/^\s+/, '')
          def #{name}_display
          [TAB]'<i class="bi bi-check-circle-fill h3 text-warning"></i>'.html_safe if #{name}?
          end
        CODE
      end

      def datetime_code(name)
        <<-CODE.gsub(/^\s+/, '')
          def #{name}_display
          [TAB]#{name} ? I18n.l(#{name}) : ''
          end
        CODE
      end

      def date_code(name)
        <<-CODE.gsub(/^\s+/, '')
          def #{name}_display
          [TAB]#{name} ? I18n.l(#{name}) : ''
          end
        CODE
      end

      def number_code(name, decorator)
        code = decorator.digit ? "#{name}.to_formatted_s(:delimited)" : "#{name}.to_s"
        code = set_append_and_prepend(code, decorator.append, decorator.prepend)
        <<-CODE.gsub(/^\s+/, '')
          def #{name}_display
          [TAB]#{code} if #{name}.present?
          end
        CODE
      end

      def string_code(name, decorator)
        code = name
        code = set_append_and_prepend(code, decorator.append, decorator.prepend)
        <<-CODE.gsub(/^\s+/, '')
          def #{name}_display
          [TAB]#{code} if #{name}.present?
          end
        CODE
      end

      def set_append_and_prepend(code, append, prepend)
        if append.present? || prepend.present?
          "\"#{prepend}\#{#{code}}#{append}\""
        else
          code
        end
      end

      def enum_code(field)
        codes = field.enum.elements.select{ |e| e.color.present? }.map do |e|
          "[TAB]when '#{e.key}' then '#{e.color}'"
        end
        return nil if codes.blank?
        <<-CODE.gsub(/^\s+/, '')
          def #{field.name}_color
          [TAB]case #{field.name}.to_s
          #{codes.join("\n")}
          [TAB]else ''
          [TAB]end
          end
        CODE
      end
  end
end