class Admin::GroupsController < AdminController

  private

    def model
      Group
    end

    def model_params
      params.require(:group).permit(:parent_id).require(:name)
    end
end
