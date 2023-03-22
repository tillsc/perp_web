Sentry.init do |config|
  config.dsn = 'https://f14590d7aa5841d08fdd54065ecf692e@o4504883820167168.ingest.sentry.io/4504883823640576'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end