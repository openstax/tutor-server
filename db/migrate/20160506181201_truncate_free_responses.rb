class TruncateFreeResponses < ActiveRecord::Migration[4.2]
  def up
    Tasks::Models::TaskedExercise.unscoped.update_all('free_response = left(free_response, 10000)')
  end

  def down
  end
end
