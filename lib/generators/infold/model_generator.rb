require 'rails/generators/base'
require 'hashie'
require 'infold/writers/model_writer'
require 'infold/resource_config'
require 'infold/db_schema'

module Infold
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      @resource_name = name
      setting = Hashie::Mash.load(Rails.root.join("infold/#{name}.yml"))
      resource_config = ResourceConfig.new(name, setting)
      db_schema = DbSchema.new
      @writer = ModelWriter.new(resource_config, db_schema)
    end

    def create_model_file
      template "model.rb", Rails.root.join("infold/model", "#{@resource_name}_model.rb"), force: true
    end
  end
end