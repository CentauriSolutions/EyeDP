class Admin::UsersController < AdminController
  private

  def model
    User
  end

    # Never trust parameters from the scary internet, only allow the white list through.
    def model_params
      params.fetch(:user, {}).require(:user)
    end
end
