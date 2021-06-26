# frozen_string_literal: true

class Admin::SessionsController < AdminController
  skip_before_action :set_model
  def index  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    namespace = '2::'
    keys = Redis.current.keys.filter { |k| k.starts_with? namespace }
    data = Redis.current.mget(keys)
    @sessions = keys.zip(data).map do |key, sess|
      sess = JSON.parse(sess)
      {
        id: key,
        user: User.find(sess['warden.user.user.key'][0][0]),
        last_request_at: sess['warden.user.user.session']['last_request_at'],
        ip: sess['ip'],
        user_agent: sess['user-agent']
      }
    end
    @sessions.sort_by! { |s| s[:last_request_at] }.reverse!
  end

  def destroy
    Redis.current.del(params[:id])
    redirect_to admin_sessions_path, notice: 'Session was successfully terminated.'
  end
end
