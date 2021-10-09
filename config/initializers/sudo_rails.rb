# frozen_string_literal: true

# config/initializers/sudo_rails.rb
SudoRails.setup do |config|
  # On/off engine
  def config.enabled
    Setting.sudo_enabled
  end

  # Sudo mode sessions duration, default is 30 minutes
  def config.sudo_session_duration
    Setting.sudo_session_duration || 15.minutes
  end

  # Confirmation page styling
  # config.custom_logo = '/images/logo_medium.png'

  def config.custom_logo
    Setting.logo if Setting.logo && (Setting.logo[0..3] == 'http' || asset_available?(Setting.logo))
  end
  config.primary_color = '#1a7191'
  config.background_color = '#1a1a1a'
  config.layout = 'application'
end
