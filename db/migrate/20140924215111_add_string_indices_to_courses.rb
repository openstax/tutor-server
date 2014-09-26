class AddStringIndicesToCourses < ActiveRecord::Migration
  def change
    add_index :courses, [:name, :school_id], unique: true
    add_index :courses, [:short_name, :school_id], unique: true
  end
end
