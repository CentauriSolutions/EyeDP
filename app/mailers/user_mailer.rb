# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: Setting.welcome_from_email

  def group_welcome_email(user, group, address)
    @user = user
    @group = group
    mail(to: address,
         subject: "Welcome to #{@group.name}")
  end

  def force_reset_password_email(user, token, address)
    @user = user
    @token = token
    if Setting.admin_reset_email_template.present?
      @template = Liquid::Template.parse(Setting.admin_reset_email_template)
    end
    if Setting.admin_reset_email_template_plaintext.present?
      @text_template = Liquid::Template.parse(Setting.admin_reset_email_template_plaintext)
    end
    mail(to: address,
         subject: 'Password Changed')
  end

  def admin_welcome_email(user, token, address)
    @user = user
    @token = token
    if Setting.admin_welcome_email_template.present?
      @template = Liquid::Template.parse(Setting.admin_welcome_email_template)
    end
    if Setting.admin_welcome_email_template_plaintext.present?
      @text_template = Liquid::Template.parse(Setting.admin_reset_email_template_plaintext)
    end
    mail(to: address,
         subject: 'Your account has been created')
  end

  def template_variables(user)
    {
      'username' => user.username,
      'name' => user.name,
      'email' => user.email
    }
  end
  helper_method :template_variables
end
