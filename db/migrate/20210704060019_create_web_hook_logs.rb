class CreateWebHookLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :web_hook_logs, id: :uuid do |t|
      t.references :web_hook, null: false, foreign_key: true, type: :uuid
      t.text :trigger
      t.text :url
      t.text :request_data
      t.text :response_headers
      t.text :response_data
      t.text :response_status
      t.decimal :execution_duration

      t.timestamps
    end
  end
end
