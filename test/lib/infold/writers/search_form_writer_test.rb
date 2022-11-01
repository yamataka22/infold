require 'test_helper'
require 'infold/writers/search_form_writer'
require 'infold/model_config'
require 'infold/app_config'
require 'infold/db_schema'

module Infold
  class ControllerWriterTest < ::ActiveSupport::TestCase

    setup do
      @model_config = ModelConfig.new("products", {})
      @app_config = AppConfig.new("products", {})
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "set_conditions_code should generate set condition each field" do
      yaml = <<-"YAML"
        app:
          index:
            conditions:
              - id: eq
              - name: full_like
              - status: any
          association_search:
            conditions:
              - id: eq
              - status: eq
              - price: gteq
      YAML
      app_config = AppConfig.new('product', YAML.load(yaml))
      writer = SearchFormWriter.new(@model_config, app_config, @db_schema)
      code = writer.set_conditions_code
      expect_code = <<-CODE.gsub(/^\s+/, '')
        set_condition :id_eq,
        [TAB]:name_full_like,
        [TAB]:status_any,
        [TAB]:status_eq,
        [TAB]:price_gteq
      CODE
      assert_match(expect_code.gsub(/^\s+/, ''), code.gsub(/^\s+/, ''))
    end
  end
end