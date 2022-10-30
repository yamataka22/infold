require 'rails/generators/base'
require 'hashie'
require 'infold/writers/decorator_writer'
require 'infold/model_config'
require 'infold/app_config'
require 'infold/db_schema'

module Infold
  class DecoratorGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      setting = Hashie::Mash.load(Rails.root.join("infold/#{name}.yml"))
      model_config = ModelConfig.new(name, setting)
      app_config = AppConfig.new(name, setting)
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      db_schema = DbSchema.new(db_schema_content)
      @writer = DecoratorWriter.new(model_config, app_config, db_schema)
    end

    def create_model_file
      template "decorator.rb", Rails.root.join("infold/model", "#{name}_decorator.rb"), force: true
    end
  end
end