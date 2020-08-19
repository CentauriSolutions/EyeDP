EyedP::Application.config.action_mailer.default_url_options = { :host => ENV['EMAIL_DOMAIN'] }

ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
  address: ENV['SMTP_HOST'] || 'localhost',
  port: ENV['SMTP_PORT'] || 25,
  domain: ENV['SMTP_DOMAIN'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: ENV['SMTP_AUTHENTICATION'] || 'plain',
  enable_starttls_auto: true
}
