Rails.application.configure do
  default_delivery_method = Rails.env.production? ? :sendmail : :test

  config.action_mailer.delivery_method = (ENV["MAIL_DELIVERY_METHOD"].presence || default_delivery_method).to_sym

  if config.action_mailer.delivery_method == :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("MAIL_HOST", "localhost"),
      port: ENV.fetch("MAIL_PORT", 25),
      user_name: ENV["MAIL_USER"],
      password: ENV["MAIL_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true,
      domain: ENV["MAIL_DOMAIN"].presence || "perp.de"
    }
  end

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: ENV["MAIL_DOMAIN"].presence || "perp.de" }
end
