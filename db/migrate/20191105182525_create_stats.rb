class CreateStats < ActiveRecord::Migration[5.2]
  def change
    create_table :stats_intervals do |t|
      t.jsonb :stats, null: false, default: {}
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
    end

    dir.up { Stats::Generate.call }
  end
end
