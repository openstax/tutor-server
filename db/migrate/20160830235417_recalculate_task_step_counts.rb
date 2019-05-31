class RecalculateTaskStepCounts < ActiveRecord::Migration[4.2]
  def up
    Tasks::Models::Task.unscoped.find_each(&:touch)
  end

  def down
  end
end
