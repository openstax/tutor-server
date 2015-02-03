class CreateInteractives < ActiveRecord::Migration
  def change
    create_table :interactives do |t|
      t.timestamps null: false
    end
  end
end
