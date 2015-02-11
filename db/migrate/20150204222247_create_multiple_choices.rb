class CreateMultipleChoices < ActiveRecord::Migration
  def change
    create_table :multiple_choices do |t|
      t.integer :answer_id

      t.timestamps null: false
    end
  end
end
