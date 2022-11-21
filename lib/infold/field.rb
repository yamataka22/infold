require 'infold/property/validation'
require 'infold/property/active_storage'
require 'infold/property/condition'
require 'infold/property/association'
require 'infold/property/enum'
require 'infold/property/show_element'
require 'infold/property/form_element'
require 'infold/property/decorator'

module Infold
  class Field
    attr_reader :type,
                :validation,
                :enum,
                :active_storage,
                :form_element,
                :show_element,
                :decorator,
                :search_conditions,
                :association

    attr_accessor :index_list_seq,
                  :csv_seq,
                  :association_search_list_seq

    def initialize(name, type=nil)
      @name = name
      @type = type&.to_sym
      @search_conditions = []
    end

    def name(*attr)
      name = @name
      name = name.underscore if attr.include?(:snake)
      name = name.camelize if attr.include?(:camel)
      name = name.singularize if attr.include?(:single)
      name = name.pluralize if attr.include?(:multi)
      name
    end

    def build_active_storage(**attrs)
      @active_storage = ActiveStorage.new(self, **attrs)
    end

    def build_association(**attrs)
      @association = Association.new(self, **attrs)
    end

    def build_enum
      @enum = Enum.new(self)
    end

    def build_show_element(**attrs)
      @show_element = ShowElement.new(self, **attrs)
    end

    def build_form_element(**attrs)
      @form_element = FormElement.new(self, **attrs)
    end

    def build_decorator(**attrs)
      @decorator = Decorator.new(self, **attrs)
    end

    def enum?; @enum.present? end
    def decorator?; @decorator.present? end
    def association?; @association.present? end
    def validation?; @validation.present? end
    def active_storage?; @active_storage.present? end
    def form_element?; @form_element.present? end

    def add_validation(condition, options = {})
      @validation ||= Validation.new(self)
      @validation.add_conditions(condition, options)
    end

    def add_search_condition(view_kind, sign:, form_kind:, seq: 0, association_name: nil)
      form_kind = 'text' if form_kind.blank?
      condition = @search_conditions.find{ |sc| sc.sign == sign.to_sym }
      condition ||= (@search_conditions << Condition.new(self, sign: sign)).last
      if view_kind == :index
        condition.index_form_kind = form_kind
        condition.index_seq = seq
      else
        condition.association_search_form_kind = form_kind
        condition.association_seq = seq
      end
      condition.index_association_name = association_name
      condition
    end

    def datepicker?
      %w(date datetime).include?(type.to_s)
    end

    def number?
      %w(integer float decimal).include?(type.to_s)
    end

    def in_index_list?; index_list_seq.present? end
    def in_csv?; csv_seq.present? end
    def in_association_search_list?; association_search_list_seq.present? end
  end
end