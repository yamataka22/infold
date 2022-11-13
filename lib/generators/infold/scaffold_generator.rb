require 'rails/generators/base'

module Infold
  class ScaffoldGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def perform
      resource_name = name.camelize.singularize
      invoke 'infold:model',       [ resource_name ]
      invoke 'infold:decorator',   [ resource_name ]
      invoke 'infold:controller',  [ resource_name ]
      invoke 'infold:search_form', [ resource_name ]
      invoke 'infold:views',       [ resource_name ]
    end
  end
end