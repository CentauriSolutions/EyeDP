# frozen_string_literal: true

# == Schema Information
#
# Table name: settings
#
#  id         :bigint           not null, primary key
#  value      :text
#  var        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_settings_on_var  (var) UNIQUE
#

# RailsSettings Model
class Setting < ApplicationRecord

  audited

  SEPARATOR_REGEXP = /[\n,;]+/.freeze
  # cache_prefix { "v1" }

  # Define your fields

  class << self
    def field(key, **opts)
      _define_field(key, default: opts[:default], type: opts[:type], readonly: opts[:readonly])
    end

    def clear_cache
      # RequestStore.store[:rails_settings_all_settings] = nil
      Rails.cache.delete(cache_key)
    end

    def cache_prefix(&block)
      @cache_prefix = block
    end

    def cache_key
      scope = ['settings']
      scope << @cache_prefix.call if @cache_prefix
      scope.join('/')
    end

    private

    def _define_field(key, default: nil, type: :string, readonly: false)
      if readonly
        self.class.define_method(key) do
          send(:_covert_string_to_typeof_value, type, default)
        end
      else
        self.class.define_method(key) do
          val = send(:_value_of, key)
          result = nil
          if !val.nil?
            result = val
          else
            result = default
            result = default.call if default.is_a?(Proc)
          end

          result = send(:_covert_string_to_typeof_value, type, result)

          result
        end

        self.class.define_method("#{key}=") do |value|
          var_name = key.to_s

          record = find_by(var: var_name) || new(var: var_name)
          value = send(:_covert_string_to_typeof_value, type, value)

          record.value = value
          record.save!
          Setting.clear_cache
          value
        end
      end

      if type == :boolean
        self.class.define_method("#{key}?") do
          send(key)
        end
      end
    end

    def _covert_string_to_typeof_value(type, value)
      return value unless value.is_a?(String) || value.is_a?(Integer)

      case type
      when :boolean
        return value == 't' || value == 'true' || value == '1' || value == 1 || value == true
      when :array
        return value.split(SEPARATOR_REGEXP).reject(&:empty?)
      when :hash
        value = begin
                    YAML.safe_load(value).to_hash
                rescue StandardError
                  {}
                  end
        value.deep_stringify_keys!
        return value
      when :integer
        return value.to_i
      when :time
        if value.is_a?(String)
          return ActiveSupport::Duration::parse(value)
        else
          return value.iso8601
        end
      else
        value
      end
    end

    def _value_of(var_name)
      raise "#{table_name} does not exist." unless table_exists?

      _all_settings[var_name.to_s]
    end

    def rails_initialized?
      Rails.application&.initialized?
    end

    def _all_settings
      # raise "You can use settings before Rails initialize." unless rails_initialized?
      # RequestStore.store[:rails_settings_all_settings] ||= begin
      Rails.cache.fetch(cache_key, expires_in: 1.week) do
        vars = unscoped.select('var, value')
        result = {}
        vars.each { |record| result[record.var] = record.value }
        result.with_indifferent_access
      end
      # end
    end

    def idp_base_uri
      begin
        URI.parse(Setting.idp_base)
      rescue URI::InvalidURIError
      end
    end
  end

  field :idp_base
  field :saml_certificate
  field :saml_key
  field :registration_enabled, type: :boolean, default: false
  field :oidc_signing_key
  field :logo
  field :logo_height, default: 50, type: :integer
  field :logo_width, default: 100, type: :integer
  field :devise_reset_password_within, type: :time, default: 7.days.iso8601
  field :session_timeout_in, type: :time

  field :home_template, default: '', type: :string
  field :registered_home_template, default: '', type: :string

  field :welcome_from_email, type: :string, default: "noreply@#{idp_base_uri ? idp_base_uri.hostname : "example.com"}"
  field :expire_after, type: :time
  field :permanent_email, type: :boolean, default: true

  field :admin_reset_email_template, default: '', type: :string
  field :admin_welcome_email_template, default: '', type: :string

  field :html_title_base, default: 'EyeDP', type: :string

  field :webhook_timeout, default: 60, type: :integer
end
