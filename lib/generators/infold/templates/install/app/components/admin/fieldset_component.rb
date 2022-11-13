# frozen_string_literal: true

module Admin
    class FieldsetComponent < ViewComponent::Base
      def initialize(form, field=nil, kind=nil, required: false, hide_label: false, append: nil, prepend: nil, **options)
        @form = form
        @field = field
        @kind = kind
        @required = required
        @hide_label = hide_label
        @append = append
        @prepend = prepend
        @options = options || {}
      end

      def hide_label?
        @hide_label
      end

      def form_field
        case @kind
        when :text
          Admin::TextComponent.new(@form,
                                   @field,
                                   form_kind: @options[:form_kind],
                                   datepicker: @options[:datepicker])
        when :checkbox
          Admin::CheckboxComponent.new(@form,
                                       @field,
                                       @options[:list],
                                       checked_values: @options[:checked_values])
        when :datetime
          Admin::DatetimeComponent.new(@form, @field)
        when :file
          Admin::FileUploadComponent.new(@form, @field)
        when :radio
          Admin::RadioComponent.new(@form,
                                    @field,
                                    @options[:list],
                                    checked_value: @options[:checked_value])
        when :select
          Admin::SelectComponent.new(@form,
                                     @field,
                                     @options[:list],
                                     selected_value: @options[:selected_value],
                                     blank: @options[:blank])
        when :switch
          Admin::SwitchComponent.new(@form,
                                     @field,
                                     include_hidden: @options[:include_hidden])
        when :association_search
          Admin::AssociationFieldComponent.new(@options[:association_name],
                                               @options[:search_path],
                                               @form,
                                               @field,
                                               @options[:name_field],
                                               nested_form: @options[:nested_form])
        end
      end

      def input_group?
        @append || @prepend
      end
    end
end