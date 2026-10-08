class CreateLawsuits < ActiveRecord::Migration[8.1]
  def change
    create_table :lawsuits do |t|
      t.string :number, null: false
      t.string :forum, null: false
      t.string :court, null: false
      t.decimal :value, precision: 15, scale: 2, null: false
      t.integer :number_of_authors, null: false, default: 1

      t.timestamps
    end

    add_index :lawsuits, :number, unique: true
  end
end
