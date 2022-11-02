require 'rails/generators/base'
require 'infold/writers/search_form_writer'
require 'infold/resource'

module Infold
  class SearchFormGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def setup
      yaml = YAML.load_file(Rails.root.join("infold/#{name}.yml"))
      resource = Resource.new(name, yaml)
      @writer = SearchFormWriter.new(resource)
    end

    def create_model_file
      template "search_form.rb", Rails.root.join("infold/model", "#{name}_search_form.rb"), force: true
    end
  end
end