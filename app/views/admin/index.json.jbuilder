# frozen_string_literal: true

json.array! @admin_groups, partial: 'admin_groups/admin_group', as: :admin_group
