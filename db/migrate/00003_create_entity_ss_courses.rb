class CreateEntitySsCourses < ActiveRecord::Migration
  def change
    create_table :entity_ss_courses do |t|
      t.timestamps null: false
    end
  end
end
