class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      # SHA-256 digest of the session token; the raw token lives only in the
      # browser cookie and is never stored.
      t.string :token_digest, null: false
      t.string :user_agent
      t.string :ip_address
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :sessions, :token_digest, unique: true
  end
end
