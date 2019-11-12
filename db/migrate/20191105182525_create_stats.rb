class CreateStats < ActiveRecord::Migration[5.2]
  def change
    create_table :stats_intervals do |t|
      t.jsonb :stats, null: false, default: {}
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
    end
    reversible do |dir|
      dir.up   { BackgroundMigrate.perform_later 'up',   20191205182525 }
      dir.down { BackgroundMigrate.perform_later 'down', 20191205182525 }
    end
  end
end
