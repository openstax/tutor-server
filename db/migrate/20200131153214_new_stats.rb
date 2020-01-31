class NewStats < ActiveRecord::Migration[5.2]
  def up
    BackgroundMigrate.perform_later 'up', 20200131153226
  end
end
