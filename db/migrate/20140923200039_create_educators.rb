class CreateEducators < ActiveRecord::Migration
  def change
    create_table :educators do |t|
      t.references :klass, null: false
      t.references :user, null: false

      t.timestamps null: false
    end

    add_index :educators, :klass_id
    add_index :educators, :user_id
    add_index :educators, [:user_id, :klass_id], unique: true
  end
end
