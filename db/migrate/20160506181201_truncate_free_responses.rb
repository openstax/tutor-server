class TruncateFreeResponses < ActiveRecord::Migration
  def change
    Tasks::Models::TaskedExercise.update_all('free_response = left(free_response, 10000)')
  end
end
