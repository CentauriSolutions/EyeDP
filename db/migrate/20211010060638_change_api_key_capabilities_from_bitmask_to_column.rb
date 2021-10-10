class ChangeApiKeyCapabilitiesFromBitmaskToColumn < ActiveRecord::Migration[6.1]
  CABAILITIES = {
    list_groups: 1,
    read_group: 2,
    write_group: 4,
    list_users: 8,
    read_user: 16,
    write_user: 32,
    read_group_members: 64,
    write_group_members: 128,
    control_admin_groups: 256,
    read_custom_data: 512,
    write_custom_data: 1024
  }
  def up
    transaction do
      CABAILITIES.keys.each do |key|
        add_column :api_keys, key, :boolean, default: false
      end
      ApiKey.without_auditing do
        ApiKey.find_each do |api_key|
          caps = CABAILITIES.filter { |_cap, bit| api_key.capabilities_mask & bit == bit }.map { |cap, _bit| cap }
          caps.each do |capability|
            api_key.send("#{capability}=", true)
          end
          api_key.save
        end
      end
      remove_column :api_keys, :capabilities_mask
    end
  end

  def down
    transaction do
      add_column :api_keys, :capabilities_mask, :integer, null: false, default: 0

      ApiKey.without_auditing do
        ApiKey.find_each do |api_key|
          caps = CABAILITIES.keys.filter {|name| api_key.send("#{name}") }
          # caps = CABAILITIES.filter { |_cap, bit| api_key.capabilities_mask & bit == bit }.map { |cap, _bit| cap }
          caps.each do |capability|
            api_key.capabilities_mask |= CABAILITIES[capability]
          end
          api_key.save
        end
      end
      CABAILITIES.keys.each do |key|
        remove_column :api_keys, key, :boolean
      end
    end
  end
end
