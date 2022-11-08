module Infold
  class Association
    include ActiveModel::Model

    attr_reader :field,
                :kind,
                :association_table,
                :association_fields

    attr_writer :name_field

    attr_accessor :association_name,
                  :class_name,
                  :foreign_key,
                  :dependent

    def initialize(field, kind:, db_schema:, **attrs)
      @field = field
      @kind = kind
      super(**attrs)
      set_association_table(db_schema)
    end

    def belongs_to?
      kind == 'belongs_to'
    end

    def has_many?
      kind == 'has_many'
    end

    def has_one?
      kind == 'has_one'
    end

    def model_name(*attr)
      name = class_name.presence || association_name.singularize.camelize
      name = name.underscore if attr.include?(:snake)
      name = name.camelize if attr.include?(:camel)
      name = name.singularize if attr.include?(:single)
      name = name.pluralize if attr.include?(:multi)
      name
    end

    def find_or_initialize_association_field(field_name, type=nil)
      find_association_field(field_name) || (@association_fields << Field.new(field_name, type)).last
    end

    def find_association_field(field_name)
      @association_fields.find { |field| field.name == field_name }
    end

    def search_path
      "admin_#{model_name(:multi, :snake)}_path"
    end

    def name_field
      @name_field.presence || 'id'
    end

    private

      def set_association_table(db_schema)
        association_table_name = model_name(:snake, :multi)
        @association_table = db_schema.find_table(association_table_name)
        @association_fields = @association_table.columns.map { |column| Field.new(column.name, column.type) }
      end
  end
end