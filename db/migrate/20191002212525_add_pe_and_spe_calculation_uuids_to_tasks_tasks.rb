class AddPeAndSpeCalculationUuidsToTasksTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :pe_calculation_uuid, :uuid
    add_column :tasks_tasks, :spe_calculation_uuid, :uuid
  end
end
