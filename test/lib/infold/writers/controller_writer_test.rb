# require '/test/test_helper'
require 'infold/writers/controller_writer'
require 'infold/model_config'
require 'infold/db_schema'
require 'hashie'

module Infold
  class ModelWriterTest < ::ActiveSupport::TestCase

    setup do
      setting = Hashie::Mash.new
      @app_config = AppConfig.new('products', setting)
      @model_config = ModelConfig.new('products', setting)
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "new action should generate the build_association_field of the form (has_many)" do
      setting = Hashie::Mash.new
      setting.model = {
        associations: {
          has_many: {
            
          }
        }
      }
      model_config = ModelConfig.new('product', setting)
      writer = ModelWriter.new(model_config, @app_config, db_schema)
      code = writer.datetime_field_code
      assert_includes(code, "datetime_field :delivery_at")
      refute_includes(code, "datetime_field :created_at")
      refute_includes(code, "datetime_field :updated_at")
    end
  end
end