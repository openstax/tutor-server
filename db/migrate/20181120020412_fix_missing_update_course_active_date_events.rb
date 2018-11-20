class FixMissingUpdateCourseActiveDateEvents < ActiveRecord::Migration
  def up
    CourseProfile::Models::Course
      .where("\"created_at\" < '#{DateTime.new(2018).to_s(:db)}'")
      .where('"sequence_number" > 0').find_each do |course|
      OpenStax::Biglearn::Api.update_course_active_dates course: course
    end
  end

  def down
  end
end
