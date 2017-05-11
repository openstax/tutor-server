class ChangeDefaultGroupTaskStepsToRecoveryGroup < ActiveRecord::Migration
  def up
    Tasks::Models::TaskStep
      .unscoped
      .where(group_type: Tasks::Models::TaskStep.group_types[:unknown_group])
      .update_all(group_type: Tasks::Models::TaskStep.group_types[:recovery_group])
  end

  def down
    Tasks::Models::TaskStep
      .unscoped
      .where(group_type: Tasks::Models::TaskStep.group_types[:recovery_group])
      .update_all(group_type: Tasks::Models::TaskStep.group_types[:unknown_group])
  end
end
