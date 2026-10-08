class CreateSummaryFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :summary_feedbacks do |t|
      t.references :summary, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :helpful, null: false

      t.timestamps
    end

    # A user votes once per summary; voting again updates the existing row.
    add_index :summary_feedbacks, [ :summary_id, :user_id ], unique: true
  end
end
