require 'infold/writers/base_writer'

module Infold
  class ModelWriter < BaseWriter

    def association_code
      code = ''
      @resource.association_fields&.each do |association_field|
        association = association_field.association
        code += "#{association.kind} :#{association_field.name}"
        code += ", class_name: '#{association.class_name}'" if association.class_name.present?
        code += ", foreign_key: '#{association.foreign_key}'" if association.foreign_key.present?
        code += ", dependent: :#{association.dependent}" if association.dependent.present?
        code += "\n"
      end
      inset_indent(code, 2).presence
    end

    def accepts_nested_attributes_code
      code = ''
      @resource.association_fields&.select { |af| af.form_element.present?  } &.each do |association_field|
        code += "accepts_nested_attributes_for :#{association_field.name}, reject_if: :all_blank, allow_destroy: true\n"
      end
      inset_indent(code, 2).presence
    end

    def datetime_field_code
      code = ''
      @resource.datetime_fields&.each do |field|
        code += "datetime_field :#{field.name}\n"
      end
      inset_indent(code, 2).presence
    end

    def active_storage_attachment_code
      code = ''
      @resource.active_storage_fields&.each do |active_storage_field|
        base = "has_one_attached :#{active_storage_field.name}"
        thumb = active_storage_field.active_storage.thumb
        if thumb
          code += <<-CODE.gsub(/^\s+/, '')
            #{base} do |attachable|
            [TAB]attachable.variant :thumb, resize_to_#{thumb.kind}: [#{thumb.width}, #{thumb.height}]
            end
          CODE
        else
          code += "#{base}\n"
        end
        code +=  <<-CODE.gsub(/^\s+/, '')
          attr_accessor :remove_#{active_storage_field.name}
          before_validation { self.#{active_storage_field.name} = nil if remove_#{active_storage_field.name}.to_s == '1' }
        CODE
        code += "\n"
      end
      inset_indent(code, 2).presence
    end

    def validation_code
      code = ''
      @resource.validation_fields&.each do |validation_field|
        validation = validation_field.validation
        code += "validates :#{validation_field.name}, "
        code += "allow_blank: true, " unless validation.conditions.map(&:condition).include?(:presence)
        code += validation.conditions.map do |condition|
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
      @resource.datetime_fields&.each do |field|
        code << "validates :#{field.name}_date, presence: true, if: -> { #{field.name}_time.present? }"
        code << "validates :#{field.name}_time, presence: true, if: -> { #{field.name}_date.present? }"
      end
      code << "\n" if code.present?
      inset_indent(code.join("\n"), 2).presence
    end

    def enum_code
      code = []
      @resource.enum_fields&.each do |enum_field|
        enum = enum_field.enum
        elements = enum.elements.map { |element| "#{element.key}: #{element.value}" }
        code << "enum #{enum_field.name}: { #{elements.join(', ')} }, _prefix: true"
      end
      code << "\n" if code.present?
      inset_indent(code.join("\n"), 2).presence
    end

    def scope_code
      code = ''
      @resource.condition_fields&.each do |field|
        field_name = field.name
        field.search_conditions.each do |condition|
          sign = condition.sign
          where =
            if field.type == :datetime && %i(eq full_like lteq).include?(sign)
              if sign == :lteq
                <<-CODE.gsub(/^\s+/, '')
                return if v.blank?
                [TAB]begin
                [TAB][TAB]v = v.to_date.next_day
                [TAB]rescue
                [TAB]end
                [TAB]where(arel_table[:#{field_name}].#{sign}(v))
                CODE
              else
                <<-CODE.gsub(/^\s+/, '')
                return if v.blank?
                [TAB]begin
                [TAB][TAB]where(#{field_name}: v.to_date.all_day)
                [TAB]rescue
                [TAB][TAB]where(arel_table[:#{field_name}].#{sign}(v))
                [TAB]end
                CODE
              end
            else
              case sign
              when :eq
                "where(#{field_name}: v) if v.present?"
              when :full_like
                "where(arel_table[:#{field_name}].matches(" +'"%#{v}%"' + ")) if v.present?"
              when :start_with
                "where(arel_table[:#{field_name}].matches(" +'"#{v}%"' + ")) if v.present?"
              when :any
                "where(#{field_name}: v) if v.present?"
              else
                "where(arel_table[:#{field_name}].#{sign}(v)) if v.present?"
              end
            end
          code +=  <<-CODE.gsub(/^\s+/, '')
          scope :#{field_name}_#{sign}, ->(v) do
          [TAB]#{where}
          end
          CODE
          code += "\n"
        end
      end
      inset_indent(code, 2).presence
    end
  end
end