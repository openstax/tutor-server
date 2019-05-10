class CreateUserTours < ActiveRecord::Migration[4.2]

  def change
    create_table :user_tours do |t|
      t.text :identifier, null: false, index: { unique: true }
      t.timestamps null: false
    end

    create_table :user_tour_views do |t|
      t.integer :view_count, null: false, default: 0
      t.belongs_to :user_profile, foreign_key: true, null: false
      t.belongs_to :user_tour,    foreign_key: true, null: false, index: true
    end

    add_index :user_tour_views, [:user_profile_id, :user_tour_id], unique: true
  end
end
