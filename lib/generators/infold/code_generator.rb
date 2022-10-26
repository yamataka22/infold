require 'rails/generators/base'

module Infold
  class CodeGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :resource, type: :string, default: ''

    def perform
      target = options['resource']
      @resources = Dir.glob(Rails.root.join('infold/*.yml')).map do |file|
        resource = file.split('/').last.gsub('.yml', '')
        if target.blank? || target.underscore == resource
          invoke 'infold:model',     [ resource ]
          invoke 'infold:decorator', [ resource ]
        end
      end
    end
  end
end