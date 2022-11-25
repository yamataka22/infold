require_relative "lib/infold/version"

Gem::Specification.new do |spec|
  spec.name        = "infold"
  spec.version     = Infold::VERSION
  spec.authors     = ["yamataka22"]
  spec.email       = ["yamataka22@gmail.com"]
  spec.homepage    = "https://infold.dev"
  spec.summary     = "The internal tools framework for Ruby on Rails."
  spec.description = "The internal tools framework for Ruby on Rails."
  spec.license     = "MIT"
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/infold-dev/infold"
  spec.metadata["changelog_uri"] = "https://github.com/infold-dev/infold/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_development_dependency "sprockets-rails"
  spec.add_development_dependency "jsbundling-rails"
  spec.add_development_dependency "turbo-rails"
  spec.add_development_dependency "stimulus-rails"
  spec.add_development_dependency "cssbundling-rails"
  spec.add_development_dependency "jbuilder"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "devise"
  spec.add_development_dependency "kaminari"
  spec.add_development_dependency "enum_help"
  spec.add_development_dependency "view_component"
  spec.add_development_dependency "active_decorator"
  spec.add_development_dependency "haml-rails"
  spec.add_development_dependency "faker"
end
