class SetValueForNullAttemptNumbers < ActiveRecord::Migration[5.2]
  def up
    BackgroundMigrate.perform_later 'up', 20210915153151
  end

  def down
    BackgroundMigrate.perform_later 'down', 20210915153151
  end
end
