# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: Setting.welcome_from_email

  def group_welcome_email(user, group)
    @user = user
    @group = group
    mail(to: @user.email,
         subject: "Welcome to #{@group.name}")
  end

  def force_reset_password_email(user, token)
    @user = user
    @token = token
    if Setting.admin_reset_email_template.present?
      @template = Liquid::Template.parse(Setting.admin_reset_email_template)
    end
    mail(to: @user.email,
         subject: 'Password Changed')
  end

  def admin_welcome_email(user, token)
    @user = user
    @token = token
    mail(to: @user.email,
         subject: 'Your account has been created')
  end

  def template_variables(user)
    {
      'username' => user.username,
      'email' => user.email
    }
  end
  helper_method :template_variables
end
