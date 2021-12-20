class RemoveSerializedNokogiriNodes < ActiveRecord::Migration[5.2]
  def up
    BackgroundMigrate.perform_later 'up', 20211005155727
  end

  def down
    BackgroundMigrate.perform_later 'down', 20211005155727
  end
end
