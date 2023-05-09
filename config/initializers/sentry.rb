Sentry.init do |config|
  config.dsn = 'https://f14590d7aa5841d08fdd54065ecf692e@o4504883820167168.ingest.sentry.io/4504883823640576'
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  config.traces_sample_rate = 0.001
end