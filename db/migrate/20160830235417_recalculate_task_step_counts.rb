class RecalculateTaskStepCounts < ActiveRecord::Migration
  def up
    Tasks::Models::Task.unscoped.find_each(&:touch)
  end

  def down
  end
end
