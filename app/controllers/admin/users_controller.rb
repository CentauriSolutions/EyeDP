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
    %w[email groups]
  end

  def model
    User
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def model_params
    p = params.require(:user).permit(:email, groups: [])
    # binding.pry
    p[:groups] = Group.where(id: p[:groups].reject(&:empty?)) if p[:groups]
    p
  end
end
