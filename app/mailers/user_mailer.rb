# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: Setting.welcome_from_email

  def group_welcome_email(user, group)
    @user = user
    @group = group
    mail(to: @user.email,
         subject: I18n.t("Welcome to #{@group.name}"))
  end

  def force_reset_password_email(user, token)
    @user = user
    @token = token
    mail(to: @user.email,
         subject: I18n.t('Password Changed'))
  end

  def admin_welcome_email(user, token)
    @user = user
    @token = token
    mail(to: @user.email,
         subject: I18n.t('Your account has been created'))
  end
end
