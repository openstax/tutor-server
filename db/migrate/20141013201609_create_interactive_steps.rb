class CreateInteractiveSteps < ActiveRecord::Migration
  def change
    create_table :interactive_steps do |t|
      t.timestamps null: false
    end
  end
end
