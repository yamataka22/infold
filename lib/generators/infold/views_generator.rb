require 'rails/generators/base'

module Infold
  class ViewsGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def perform
      invoke 'infold:views:index', [ name ]
      invoke 'infold:views:show',  [ name ]
      # invoke 'infold:views:form',  [ name ]
      # invoke 'infold:views:association_search', [ name ]
    end
  end
end