# config/initializers/sudo_rails.rb
SudoRails.setup do |config|
  # On/off engine
  config.enabled = true

  # Sudo mode sessions duration, default is 30 minutes
  config.sudo_session_duration = 15.minutes

  # Confirmation page styling
  config.custom_logo = '/images/logo_medium.png'
  config.primary_color = '#1a7191'
  config.background_color = '#1a1a1a'
  config.layout = 'application'

  # Confirmation strategy implementation
  config.confirm_strategy = -> (context, password) {
    user = context.current_user
    user.valid_password?(password)
  }

  # Reset password link
  config.reset_pass_link = '/users/password/new'
end