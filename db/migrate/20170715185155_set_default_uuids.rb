class SetDefaultUuids < ActiveRecord::Migration
  def up
    execute 'update course_profile_courses set uuid = gen_random_uuid() where uuid is null'
    change_column_null :course_profile_courses, :uuid, false
  end
end
