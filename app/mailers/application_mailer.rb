# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Setting.welcome_from_email
  layout 'mailer'
end
