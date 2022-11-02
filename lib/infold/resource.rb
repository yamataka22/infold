require "active_support/core_ext/hash/indifferent_access"
require 'infold/resource_model'
require 'infold/resource_app'
require 'infold/db_schema'

module Infold
  class Resource
    include ResourceModel
    include ResourceApp

    attr_reader :name

    def initialize(name, resource_yaml, db_schema=nil)
      @name = name
      @resource_yaml = resource_yaml.with_indifferent_access
      @db_schema = db_schema || DbSchema.new(File.read(Rails.root.join('db/schema.rb')))
    end

    def model
      @resource_yaml.dig('model') || {}
    end

    def app
      @resource_yaml.dig('app') || {}
    end

    def table(name)
      @db_schema.table(name)
    end

    def self_table
      @db_schema.table(name)
    end
  end
end