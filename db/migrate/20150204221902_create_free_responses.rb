class CreateFreeResponses < ActiveRecord::Migration
  def change
    create_table :free_responses do |t|
      t.timestamps null: false
    end
  end
end
