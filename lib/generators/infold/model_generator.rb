require 'rails/generators/base'
require 'infold/writer/model_writer'
require 'infold/resource_config'

module Infold
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      @writer = ModelWriter.new(name)
    end

    def create_model_file
      template "model.rb", Rails.root.join("infold/model", "#{name}_model.rb"), force: true
    end
  end
end