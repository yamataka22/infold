require 'rails/generators/base'
require 'infold/writers/view_writer'
require 'infold/resource'

module Infold
  class ViewGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      yaml = YAML.load_file(Rails.root.join("infold/#{name}.yml"))
      resource = Resource.new(name, yaml)
      @writer = ViewWriter.new(resource)
    end

    def index_file
      template "views/index.haml", Rails.root.join("infold/model", "#{name}_view_index.html.haml"), force: true
    end

    def index_row_file
      template "views/_index_row.haml", Rails.root.join("infold/model", "#{name}_view_index_row.html.haml"), force: true
    end
  end
end