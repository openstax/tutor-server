class CreateTopics < ActiveRecord::Migration
  def change
    create_table :topics do |t|
      t.references :klass
      t.string :name

      t.timestamps null: false
    end

    add_index :topics, [:klass_id, :name], unique: true
  end
end
