class FixExistingTaskCaches < ActiveRecord::Migration[5.2]
  def up
    Tasks::Models::Task.where(is_provisional_score_after_due: true).find_each(&:update_caches_later)
  end

  def down
  end
end
