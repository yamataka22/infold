require 'infold/writers/base_writer'

module Infold
  class ModelWriter < BaseWriter

    def association_code
      code = ''
      @resource.model_associations&.each do |model_association|
        code += "#{model_association.kind} :#{model_association.field}"
        options = model_association.options&.map { |key, value| "#{key}: '#{value}'" }
        code += ", #{options.join(', ')}" if options.present?
        code += "\n"
      end
      if @resource.form_associations.present?
        code += "\n"
        @resource.form_associations.each do |form_association|
          code += "accepts_nested_attributes_for :#{form_association.field}, reject_if: :all_blank, allow_destroy: true\n"
        end
      end
      inset_indent(code, 2).presence
    end

    def datetime_field_code
      code = ''
      @resource.self_table.datetime_columns.each do |column|
        code += "datetime_field :#{column}\n"
      end
      inset_indent(code, 2).presence
    end

    def active_storage_attachment_code
      code = ''
      @resource.active_storages&.each do |active_storage|
        base = "has_one_attached :#{active_storage.field}"
        if active_storage.thumb
          code += <<-CODE.gsub(/^\s+/, '')
            #{base} do |attachable|
            [TAB]attachable.variant :thumb, resize_to_#{active_storage.thumb.kind}: [#{active_storage.thumb.width}, #{active_storage.thumb.height}]
            end
          CODE
        else
          code += "#{base}\n"
        end
        code +=  <<-CODE.gsub(/^\s+/, '')
          attr_accessor :remove_#{active_storage.field}
          before_validation { self.#{active_storage.field} = nil if remove_#{active_storage.field}.to_s == '1' }
        CODE
        code += "\n"
      end
      inset_indent(code, 2).presence
    end

    def validation_code
      code = ''
      @resource.validates&.each do |validate|
        code += "validates :#{validate.field}, "
        code += "allow_blank: true, " unless validate.conditions.map(&:condition).include?('presence')
        code += validate.conditions.map do |condition|
          if condition.options.blank?
            "#{condition.condition}: true"
          else
            "#{condition.condition}: { #{condition.options.map { |key, value| "#{key}: #{value}" }.join(', ')} }"
          end
        end.join(', ')
        code += "\n"
      end
      inset_indent(code, 2).presence
    end

    def datetime_validation_code
      code = []
      @resource.self_table.datetime_columns&.each do |column|
        code << "validates :#{column}_date, presence: true, if: -> { #{column}_time.present? }"
        code << "validates :#{column}_time, presence: true, if: -> { #{column}_date.present? }"
      end
      code << "\n" if code.present?
      inset_indent(code.join("\n"), 2).presence
    end

    def enum_code
      code = []
      @resource.enum&.each do |enum|
        elements = enum.elements.map { |element| "#{element.key}: #{element.value}" }
        code << "enum #{enum.field}: { #{elements.join(', ')} }, _prefix: true"
      end
      code << "\n" if code.present?
      inset_indent(code.join("\n"), 2).presence
    end

    def scope_code
      code = ''
      table = @resource.table(@resource.name)
      conditions = @resource.index_conditions.to_a + @resource.association_search_conditions.to_a
      conditions.map { |c| { field: c.field, sign: c.sign } }.uniq.each do |condition|
        field = condition[:field]
        sign = condition[:sign]
        column = table.columns.find { |c| c.name == field }
        where =
          if column&.type.to_s == 'datetime' && %w(eq full_like lteq).include?(sign)
            if sign == 'lteq'
              <<-CODE.gsub(/^\s+/, '')
                return if v.blank?
                [TAB]begin
                [TAB][TAB]v = v.to_date.next_day
                [TAB]rescue
                [TAB]end
                [TAB]where(arel_table[:#{field}].#{sign}(v))
              CODE
            else
              <<-CODE.gsub(/^\s+/, '')
                return if v.blank?
                [TAB]begin
                [TAB][TAB]where(#{field}: v.to_date.all_day)
                [TAB]rescue
                [TAB][TAB]where(arel_table[:#{field}].#{sign}(v))
                [TAB]end
              CODE
            end
          else
            case sign
            when 'eq'
              "where(#{field}: v) if v.present?"
            when 'full_like'
              "where(arel_table[:#{field}].matches(" +'"%#{v}%"' + ")) if v.present?"
            when 'start_with'
              "where(arel_table[:#{field}].matches(" +'"#{v}%"' + ")) if v.present?"
            when 'any'
              "where(#{field}: v) if v.present?"
            else
              "where(arel_table[:#{field}].#{sign}(v)) if v.present?"
            end
          end
        code +=  <<-CODE.gsub(/^\s+/, '')
          scope :#{field}_#{sign}, ->(v) do
          [TAB]#{where}
          end
        CODE
        code += "\n"
      end
      inset_indent(code, 2).presence
    end

    private

      def options(code, options)
        if options.present?
          options = options.map { |key, value| "#{key}: '#{value}'" }
          code += ", #{options.join(', ')}"
        end
        code
      end
  end
end