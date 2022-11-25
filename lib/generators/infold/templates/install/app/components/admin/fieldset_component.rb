# frozen_string_literal: true

module Admin
  class FieldsetComponent < ViewComponent::Base
    def initialize(form, field=nil, kind=nil, required: false, label: nil, no_label: false, alignment: true, append: nil, prepend: nil, **options)
      @form = form
      @field = field
      @kind = kind
      @required = required
      @label = label
      @no_label = no_label
      @alignment = alignment
      @append = append
      @prepend = prepend
      @options = options || {}
    end

    def label_rendering?
      !@no_label
    end

    def alignment?
      @alignment && label_rendering?
    end

    def form_field
      case @kind
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
                                   blank: @options[:blank] || true)
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
      else
        kind = @kind == :text_area ? :text_area : "#{@kind}_field"
        Admin::TextComponent.new(@form,
                                 @field,
                                 form_kind: kind,
                                 placeholder: @options[:placeholder],
                                 datepicker: @options[:datepicker])
      end
    end

    def input_group?
      @append || @prepend
    end
  end
end