# frozen_string_literal: true

if Rails.env.development?
  require 'rails_erd/domain'

  module RailsERD
    class Domain
      def name
        return unless defined?(Rails) && Rails.application

        if Rails.application.class.respond_to?(:module_parent)
          Rails.application.class.module_parent.name
        else
          Rails.application.class.parent.name
        end
      end
    end
  end
end
