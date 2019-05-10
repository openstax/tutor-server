class CreateTimeZones < ActiveRecord::Migration[4.2]
  def change
    create_table :time_zones do |t|
      t.string :name, null: false, index: true

      t.timestamps null: false
    end
  end
end
