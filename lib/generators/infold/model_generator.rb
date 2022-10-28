require 'rails/generators/base'
require 'hashie'
require 'infold/writers/model_writer'
require 'infold/resource_config'
require 'infold/db_schema'

module Infold
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      setting = Hashie::Mash.load(Rails.root.join("infold/#{name}.yml"))
      resource_config = ResourceConfig.new(name, setting)
      db_schema_content = File.read(Rails.root.join('db/schema.rb'))
      db_schema = DbSchema.new(db_schema_content)
      @writer = ModelWriter.new(resource_config, db_schema)
    end

    def create_model_file
      template "model.rb", Rails.root.join("infold/model", "#{name}_model.rb"), force: true
    end
  end
end