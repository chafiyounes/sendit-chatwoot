if ENV['BREVO_API_KEY'].present?
  require Rails.root.join('lib/brevo_delivery_method')
  ActionMailer::Base.add_delivery_method :brevo, BrevoDeliveryMethod,
                                         api_key: ENV['BREVO_API_KEY'],
                                         sender_email: ENV.fetch('MAILER_SENDER_EMAIL', nil)
end

Rails.application.configure do
  config.action_mailer.default_url_options = { host: ENV['FRONTEND_URL'] } if ENV['FRONTEND_URL'].present?
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  smtp_settings = {
    address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
    port: ENV.fetch('SMTP_PORT', 587)
  }

  smtp_settings[:authentication] = ENV.fetch('SMTP_AUTHENTICATION', 'login').to_sym if ENV['SMTP_AUTHENTICATION'].present?
  smtp_settings[:domain] = ENV['SMTP_DOMAIN'] if ENV['SMTP_DOMAIN'].present?
  smtp_settings[:user_name] = ENV.fetch('SMTP_USERNAME', nil)
  smtp_settings[:password] = ENV.fetch('SMTP_PASSWORD', nil)
  smtp_settings[:enable_starttls_auto] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', true))
  smtp_settings[:openssl_verify_mode] = ENV['SMTP_OPENSSL_VERIFY_MODE'] if ENV['SMTP_OPENSSL_VERIFY_MODE'].present?
  smtp_settings[:ssl] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_SSL', true)) if ENV['SMTP_SSL']
  smtp_settings[:tls] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_TLS', true)) if ENV['SMTP_TLS']
  smtp_settings[:open_timeout] = ENV['SMTP_OPEN_TIMEOUT'].to_i if ENV['SMTP_OPEN_TIMEOUT'].present?
  smtp_settings[:read_timeout] = ENV['SMTP_READ_TIMEOUT'].to_i if ENV['SMTP_READ_TIMEOUT'].present?

  config.action_mailer.smtp_settings = smtp_settings
  config.action_mailer.delivery_method = :letter_opener if Rails.env.development? && ENV['LETTER_OPENER']
end

# Set delivery method OUTSIDE the configure block so it isn't overridden
unless Rails.env.test?
  if ENV['BREVO_API_KEY'].present?
    ActionMailer::Base.delivery_method = :brevo
  elsif ENV['SMTP_ADDRESS'].present?
    ActionMailer::Base.delivery_method = :smtp
  else
    ActionMailer::Base.delivery_method = :sendmail
  end
end