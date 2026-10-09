class CreateSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :summaries do |t|
      t.references :lawsuit, null: false, foreign_key: true
      t.text :body, null: false
      # SHA-256 of the ordered movements used to build the prompt; part of
      # the cache key so a new/changed movement invalidates the cache.
      t.string :movements_digest, null: false
      t.string :prompt_version, null: false
      t.string :provider, null: false
      t.string :model, null: false
      t.integer :input_tokens
      t.integer :output_tokens

      t.timestamps
    end

    add_index :summaries, [ :lawsuit_id, :movements_digest, :prompt_version, :model ],
      unique: true, name: "index_summaries_on_cache_key"
  end
end
