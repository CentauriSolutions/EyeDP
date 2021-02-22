class ChangeSettingIdToUuid < ActiveRecord::Migration[6.1]
  def change
    add_column :settings, :uuid, :uuid, default: "gen_random_uuid()", null: false

    change_table :settings do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute "ALTER TABLE settings ADD PRIMARY KEY (id);"
  end
end
