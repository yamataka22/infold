require 'rails/generators/base'

module Infold
  class DecoratorGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_file
      @name = name
      template "decorator.rb", Rails.root.join("infold/decorator", "#{@name}_decorator.rb")
    end
  end
end