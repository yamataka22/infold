require 'rails/generators/base'

module Infold
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates/install', __dir__)

    def check_devise_installed
      initializer_file =
        File.join(Rails.root, "config", "initializers", "devise.rb")
      @devise_installed = File.exist?(initializer_file)
    end

    def install_devise
      require "devise"

      if @devise_installed
        log :generate, "No need to install devise, already done."
      else
        log :generate, "devise:install"
        invoke "devise:install"
      end
    end

    def create_devise_user
      invoke "devise", ["admin_User"]
    end

    def delete_devise_routes
      routes_file = File.join(destination_root, "config", "routes.rb")
      gsub_file routes_file, /devise_for :admin_users.*$/, ""
    end

    def edit_devise_config
      config_file = File.join(destination_root, "config", "initializers", "devise.rb")
      gsub_file config_file, /# config.scoped_views = false$/, "config.scoped_views = true"
      unless @devise_installed
        gsub_file config_file, /# config.parent_controller = 'DeviseController'$/, "config.parent_controller = 'Admin::TurboDeviseController'"
        gsub_file config_file, "# config.navigational_formats = ['*/*', :html]", "config.navigational_formats = ['*/*', :html, :turbo_stream]"
        gsub_file config_file, "# config.warden do |manager|", "config.warden do |manager|\n    manager.failure_app = TurboFailureApp\n  end"
        code = <<-CODE.gsub(/^\s+/, '')
          # Turbo doesn't work with devise by default.
          # Keep tabs on https://github.com/heartcombo/devise/issues/5446 for a possible fix
          # Fix from https://gorails.com/episodes/devise-hotwire-turbo
          class TurboFailureApp < Devise::FailureApp
          [TAB]def respond
          [TAB][TAB]if request_format == :turbo_stream
          [TAB][TAB][TAB]redirect
          [TAB][TAB]else
          [TAB][TAB][TAB]super
          [TAB][TAB]end
          [TAB]end
          
          [TAB]def skip_format?
          [TAB][TAB]%w(html turbo_stream */*).include? request_format.to_s
          [TAB]end
          end
        CODE
        inject_into_file(config_file, before: "Devise.setup do |config|") { code.gsub('[TAB]', '  ') }
      end
    end

    def copy_app_files
      template_path = File.expand_path("templates/install", __dir__)
      Dir.glob("#{template_path}/app/**/*").each do |item|
        next if FileTest.directory?(item)
        dist_path = item.to_s.gsub(template_path.to_s, Rails.root.to_s)
        template item, dist_path, encoding: :utf8, ask: true
      end
    end

    def edit_routes_file
      template "config/routes/admin.rb", "config/routes/admin.rb", ask: true
      route "draw(:admin)"
    end

    def add_gems
      gem "sassc-rails"
    end

    def copy_locale_files
      template_path = File.expand_path("templates/install/config/locales", __dir__)
      Dir.glob("#{template_path}/*") do |item|
        dist_path = Rails.root.join("config/locales", item.split('/').last)
        template item, dist_path, encoding: :utf8, ask: true
      end
    end
  end
end