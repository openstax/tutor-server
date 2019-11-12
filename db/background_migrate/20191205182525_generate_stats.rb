class GenerateStats < ActiveRecord::Migration[5.2]
  def up
    # add indexes so exercise response validation can be queried efficiently
    add_index :tasks_tasked_exercises,
      "coalesce(jsonb_array_length(response_validation->'attempts'), 0)",
      name: :tasked_exercise_nudges_index
    add_index :tasks_tasked_exercises, :updated_at
    # then generate the stats
    Stats::Generate.call
  end

  def down
    remove_index :tasks_tasked_exercises, name: :tasked_exercise_nudges_index
    remove_index :tasks_tasked_exercises, :updated_at
  end
end
