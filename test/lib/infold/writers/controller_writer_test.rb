# require '/test/test_helper'
require 'infold/writers/controller_writer'
require 'infold/model_config'
require 'infold/db_schema'

module Infold
  class ControllerWriterTest < ::ActiveSupport::TestCase

    setup do
      @model_config = ModelConfig.new(name, {})
      @app_config = AppConfig.new(name, {})
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      @db_schema = DbSchema.new(db_schema_content)
    end

    test "new action should generate the build_association_field of the form (has_many)" do
    end
  end
end