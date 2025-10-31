# require File.expand_path('../boot', __FILE__)
require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'propshaft'
require 'dartsass-rails'
require 'importmap-rails'

module Qawamis
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers

    config.load_defaults 8.1
    config.generators.system_tests = nil

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run 'rake -D time' for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # All translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :en

    config.load_defaults 8.1
  end
end
