require 'infold/writers/views/base_writer'

module Infold::Views
  class ShowWriter < BaseWriter

    attr_reader :app_title

    def initialize(resource, app_title=nil)
      @resource = resource
      @app_title = app_title || @resource.name
    end

    def show_fields; @resource.show_fields end

  end
end