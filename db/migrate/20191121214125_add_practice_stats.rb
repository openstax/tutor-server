class AddPracticeStats < ActiveRecord::Migration[5.2]
  def up
    BackgroundMigrate.perform_later 'up', 20191121182525
  end
end
