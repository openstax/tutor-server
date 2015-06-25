class CreateCourseDetailDistricts < ActiveRecord::Migration
  def change
    create_table :course_detail_districts do |t|
      t.string :name
    end
  end
end
