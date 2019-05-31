# frozen_string_literal: true

json.extract! group, :id, :parent_id, :name, :created_at, :updated_at
json.url group_url(group, format: :json)
