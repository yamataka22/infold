# frozen_string_literal: true

module Admin
  class AssociationFieldComponent < ViewComponent::Base
    def initialize(association_name, search_path, form, id_field, name_field, nested_form:false)
      @association_name = association_name
      @search_path = search_path
      @form = form
      @id_field = id_field
      @name_field = name_field
      @nested_form = nested_form
      @turbo_frame_id = "relation_#{ SecureRandom.hex(3) }#{ @nested_form ? '_NEW_RECORD' : '' }"
    end

    def name_field_tag
      classes = %W(form-control)
      classes << 'is-invalid' if helpers.admin_field_invalid?(@form, @id_field) || helpers.admin_field_invalid?(@form, @association_name)
      text_field_tag '',
                     @form.object.send(@name_field),
                     disabled: true,
                     class: classes.join(' '),
                     data: { relation_search_target: 'selectedName' }
    end
  end
end