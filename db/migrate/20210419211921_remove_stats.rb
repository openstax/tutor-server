class RemoveStats < ActiveRecord::Migration[5.2]
  def change
    drop_table :stats_intervals
  end
end
