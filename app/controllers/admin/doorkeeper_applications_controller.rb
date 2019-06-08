# frozen_string_literal: true

class Admin::DoorkeeperApplicationsController < AdminController
  private

  # def model_attributes
  #   %w[name parent permissions]
  # end

  # def includes
  #   %i[parent permissions]
  # end

  def model
    Doorkeeper::Application
  end

  def model_name
    'doorkeeper_application'
  end

  def model_params
    # p = params.require(:group).permit(:name, :parent, permissions: [])
    # # binding.pry
    # p[:parent_id] = p.delete(:parent) if p[:parent]
    # p[:permissions] = [] if p[:permissions].nil?
    # p[:permissions].filter!(&:present?)
    # p[:permissions] = Permission.find(p[:permissions]) if p[:permissions].any?
    # p
    params.require('doorkeeper_application').permit(:name, :uid, :secret, :scopes, :redirect_uri, :confidential)
  end
end
