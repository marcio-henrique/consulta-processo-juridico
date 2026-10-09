class CreateMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :movements do |t|
      t.references :lawsuit, null: false, foreign_key: { on_delete: :cascade }
      t.date :occurred_on, null: false
      t.string :title, null: false
      t.text :content
      # 1-based index of the row in the source CSV; tie-breaker for display
      # and chronological ordering when occurred_on is the same day.
      t.integer :source_row, null: false

      t.timestamps
    end

    add_index :movements, [ :lawsuit_id, :occurred_on, :source_row ],
      order: { occurred_on: :desc, source_row: :asc },
      name: "index_movements_on_lawsuit_and_display_order"
  end
end
