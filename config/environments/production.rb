Rails.application.configure do
  config.force_ssl = true
  # config.ssl_options = { hsts: { expires: 31536000, preload: true } } # 1 year

  config.cache_classes = true
  config.cache_store = :mem_cache_store
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.log_level = :info
  config.log_tags  = [:request_id]
  config.assets.quiet = true
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
  config.serve_static_files = true
  
  config.importmap.enabled = true
  config.importmap.cache_assets = true
  config.public_file_server.enabled = true
end
