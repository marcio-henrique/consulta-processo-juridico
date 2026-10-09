# ADR-0004 / spec 06: emails are unique case-insensitively. The model stores
# them lower-cased; the functional index is the database-level safety net.
class UseCaseInsensitiveUniqueEmailIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :email, unique: true
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
