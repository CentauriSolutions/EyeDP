# frozen_string_literal: true

class Admin::DashboardController < AdminController
  def index
    @logins = Login.order(created_at: :desc).limit(50).includes(:service_provider, :user)
  end

  def jobs; end

  private

  def logins_by_app
    @logins_by_app ||= begin
      logins = Login.group(%i[service_provider_type service_provider_id])
                    .where('created_at > ?', 7.days.ago).count
      logins = logins.map do |deets, count|
        app = deets[0].constantize.find(deets[1])
        [app, count]
      end
      logins.sort_by { |login| - login[1] }.take(10)
    end
  end
  helper_method :logins_by_app

  def logins_by_user
    @logins_by_user ||= Login.group(:user)
                             .where('created_at > ?', 7.days.ago)
                             .count
                             .sort_by { |login| - login[1] }
                             .take(10)
  end
  helper_method :logins_by_user
end
