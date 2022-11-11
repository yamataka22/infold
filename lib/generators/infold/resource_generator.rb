require 'rails/generators/base'

module Infold
  class ResourceGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_resource_file
      @name = name.camelize.singularize
      template "resource.yml", Rails.root.join("infold", "#{@name.underscore}.yml"), skip: true
    end
  end
end