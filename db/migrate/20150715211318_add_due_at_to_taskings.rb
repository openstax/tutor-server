class AddDueAtToTaskings < ActiveRecord::Migration
  def change
    add_column :tasks_taskings, :due_at, :datetime,
                                         null: false,
                                         default: Time.current + 1.week
  end
end
