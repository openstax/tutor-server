class ResetIsCollege < ActiveRecord::Migration
  def up
    sanitized_date = CourseProfile::Models::Course.sanitize DateTime.new(2017, 6, 30)
    CourseProfile::Models::Course
      .where(is_preview: false, is_college: true)
      .where("created_at >= #{sanitized_date}")
      .update_all(is_college: nil)
  end

  def down
  end
end
