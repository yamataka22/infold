require 'rails/generators/base'
require 'infold/writers/controller_writer'
require 'infold/model_config'
require 'infold/app_config'
require 'infold/db_schema'

module Infold
  class ControllerGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      yaml = YAML.load_file(Rails.root.join("infold/#{name}.yml"))
      model_config = ModelConfig.new(name, yaml)
      app_config = AppConfig.new(name, yaml)
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      db_schema = DbSchema.new(db_schema_content)
      @writer = ControllerWriter.new(model_config, app_config, db_schema)
    end

    def create_model_file
      template "controller.rb", Rails.root.join("infold/model", "#{name}_controller.rb"), force: true
    end
  end
end