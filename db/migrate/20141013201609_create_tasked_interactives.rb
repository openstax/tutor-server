class CreateTaskedInteractives < ActiveRecord::Migration
  def change
    create_table :tasked_interactives do |t|
      t.timestamps null: false
    end
  end
end
