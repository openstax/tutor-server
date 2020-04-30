class NullAnswerId < ActiveRecord::Migration[5.2]
  def change
    change_column_null :tasks_tasked_exercises, :correct_answer_id, true
  end
end
