class Admin::GroupsController < AdminController



  private

    def model
      Group
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_group_params
      params.fetch(:admin_group, {})
    end
end
