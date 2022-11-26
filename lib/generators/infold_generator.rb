require 'rails/generators/base'

class InfoldGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def perform
    resource_name = name.camelize.singularize
    invoke 'infold:resource',    [ resource_name ]
    invoke 'infold:scaffold',    [ resource_name ]
  end
end