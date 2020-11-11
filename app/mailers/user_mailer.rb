# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: Setting.welcome_from_email
  layout false

  def group_welcome_email(user, group)
    @user = user
    @group = group
    mail(to: @user.email,
         subject: "Welcome to #{@group.name}")
  end
end
