# frozen_string_literal: true

class Admin::SamlServiceProvidersController < AdminController
  # def new
  #   binding.pry
  #   super
  # end

  private

  def model_attributes
    %w[name display_url show_on_dashboard image_url order description issuer_or_entity_id metadata_url fingerprint
       response_hosts allow_path_in_redirects groups]
  end

  def new_fields
    %w[name display_url show_on_dashboard image_url order description issuer_or_entity_id metadata_url fingerprint
       allow_path_in_redirects response_hosts]
  end

  def model
    SamlServiceProvider
  end

  def model_params # rubocop:disable Metrics/MethodLength
    p = params
        .require(:saml_service_provider)
        .permit(
          :name, :display_url, :show_on_dashboard,
          :image_url, :description, :order,
          :issuer_or_entity_id, :metadata_url,
          :fingerprint, :response_hosts, group_ids: []
        )
    p[:group_ids]&.reject!(&:empty?)
    p[:group_ids] ||= []
    p[:response_hosts] = p[:response_hosts].split(/ +/) if p[:response_hosts]
    p
  end

  def help_text(field_name)
    {
      'order' => 'What order should this application appear in on the user dashboard'
    }[field_name]
  end
  helper_method :help_text

  def ensure_user_is_authorized!
    raise(ActionController::RoutingError, 'Not Found') \
      unless current_user&.admin? || current_user&.operator?
  end
end
