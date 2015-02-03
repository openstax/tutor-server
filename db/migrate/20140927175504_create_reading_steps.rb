class CreateReadingSteps < ActiveRecord::Migration
  def change
    create_table :reading_steps do |t|
      t.timestamps null: false
    end
  end
end
