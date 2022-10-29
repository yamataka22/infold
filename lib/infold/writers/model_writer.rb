require 'infold/writers/base_writer'

module Infold
  class ModelWriter < BaseWriter

    def self_table
      db_schema.table(@resource_config.resource_name)
    end

    def model_name
      self_table.model_name
    end

    def association_code
      code = ''
      @resource_config.model_associations&.each do |model_association|
        code += "#{model_association.kind} :#{model_association.field}"
        options = model_association.options&.map { |key, value| "#{key}: '#{value}'" }
        code += ", #{options.join(', ')}" if options.present?
        code += "\n"
      end
      if @resource_config.form_associations.present?
        code += "\n"
        @resource_config.form_associations.each do |form_association|
          code += "accepts_nested_attributes_for :#{form_association.field}, reject_if: :all_blank, allow_destroy: true\n"
        end
      end
      inset_indent(code, 2).presence
    end

    def datetime_field_code
      code = ''
      self_table.datetime_columns.each do |column|
        code += "datetime_field :#{column}\n"
      end
      inset_indent(code, 2).presence
    end

    def active_storage_attachment_code
      code = ''
      @resource_config.active_storages&.each do |active_storage|
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
      @resource_config.validates&.each do |validate|
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
      self_table.datetime_columns&.each do |column|
        code << "validates :#{column}_date, presence: true, if: -> { #{column}_time.present? }"
        code << "validates :#{column}_time, presence: true, if: -> { #{column}_date.present? }"
      end
      code << "\n" if code.present?
      inset_indent(code.join("\n"), 2).presence
    end

    def enum_code
      code = []
      @resource_config.enum&.each do |enum|
        elements = enum.elements.map { |element| "#{element.key}: #{element.value}" }
        code << "enum #{enum.field}: { #{elements.join(', ')} }, _prefix: true"
      end
      code << "\n" if code.present?
      inset_indent(code.join("\n"), 2).presence
    end

    def delegate_code

    end

    def scope_code

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