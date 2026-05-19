ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Load seeds for tests since no fixtures exist and tests check real indices.
  Rails.application.load_seed if Book.count == 0
end

