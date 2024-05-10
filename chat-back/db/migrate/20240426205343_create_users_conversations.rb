class CreateUsersConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :users_conversations, primary_key: %i[user_id conversation_id] do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
