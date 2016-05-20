class CreateTimeZones < ActiveRecord::Migration
  def change
    create_table :time_zones do |t|
      t.string :name, null: false, index: true

      t.timestamps null: false
    end
  end
end
