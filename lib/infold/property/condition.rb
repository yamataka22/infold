module Infold
  class Condition
    include ActiveModel::Model

    attr_reader :field
    attr_writer :sign
    attr_accessor :index_form_kind,
                  :index_association_name,
                  :association_search_form_kind

    def initialize(field, **attrs)
      @field = field
      super(**attrs)
    end

    def sign
      (@sign.presence || :eq).to_sym
    end

    def scope
      "#{field.name}_#{sign}"
    end

    def in_index?
      index_form_kind.present?
    end

    def in_association_search?
      association_search_form_kind.present?
    end

    def form_kind(view)
      _form_kind = (view == :index ? index_form_kind : association_search_form_kind).to_s
      if _form_kind == 'association_search' && field.association&.belongs_to?
        :association_search
      elsif _form_kind == 'select'
        :select
      elsif sign == :any && field.enum.present?
        :checkbox
      elsif _form_kind == 'switch'
        :switch
      else
        :text
      end
    end

    def sign_label
      case sign
      when :lteq then 'or less'
      when :gteq then 'or more'
      when :full_like then 'like %@%'
      when :start_with then 'like @%'
      else '='
      end
    end
  end
end