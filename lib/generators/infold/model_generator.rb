require 'rails/generators/base'

module Infold
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_file
      @name = name
      template "model.rb", Rails.root.join("infold/model", "#{@name}_model.rb"), force: true
    end
  end
end