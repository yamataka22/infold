module Infold
  class ShowElement
    include ActiveModel::Model

    attr_reader :field,
                :association_fields

    attr_accessor :association

    def initialize(field, **attrs)
      @field = field
      @association_fields = []
      super(**attrs)
    end

    def add_association_fields(field, **attrs)
      field.build_show_element(**attrs)
      @association_fields << field
    end

    def kind_association?
      field.association.present?
    end
  end
end