class TruncateFreeResponses < ActiveRecord::Migration
  def up
    Tasks::Models::TaskedExercise.update_all('free_response = left(free_response, 10000)')
  end

  def down
  end
end
