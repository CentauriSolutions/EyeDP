# frozen_string_literal: true

class Admin::UsersController < AdminController
  private

  # def model_attributes
  #   model.attribute_names - ['id', 'created_at', 'updated_at', 'encrypted_password']
  # end

  def form_relations
    {
      groups: {
        type: :select,
        html_options: { multiple: true },
        # options: {selected: @model.groups},
        finder: lambda {
                  helpers.options_from_collection_for_select(Group.all, :id, :name, @model.groups.pluck(:id))
                }
      }
    }
  end

  def includes
    [:groups]
  end

  def whitelist_attributes
    %w[email name username groups]
  end

  def model
    User
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def model_params
    p = params.require(:user).permit(:email, :username, :password, :email, :name, groups: [])
    # binding.pry
    p[:groups] = Group.where(id: p[:groups].reject(&:empty?)) if p[:groups]
    p.delete(:password) if p[:password].empty?
    p
  end

  def sort_whitelist
    %w[created_at username email]
  end

  def filter_whitelist
    %w[username email]
  end

  def filter
    if filter_whitelist.include? params[:filter_by]
      users = User.arel_table
      users[params[:filter_by]].matches("%#{params[:filter]}%")
    else
      {}
    end
  end
end
