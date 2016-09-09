# Fix users enrolled multiple times in the same course

desc "Fix users enrolled multiple times in the same course"
task :fix_multi_enrollments, [:run_mode] => :environment do |t, args|
  real_run = (args || {})[:run_mode] == 'real'

  double_enrollments_array = []

  ActiveRecord::Base.transaction do
    CSV.open('multi-enrollments.csv', 'w+') do |csv|
      csv << ['Student Name', 'Teacher(s)', 'School']

      User::Models::Profile.preload(roles: [:teacher, {student: :course}]).find_each do |user|
        # Teacher: skip
        next if user.roles.map(&:teacher).compact.any?

        students_by_course = user.roles.map(&:student).compact.group_by(&:course)
        double_enrollments = students_by_course.keep_if{ |course, students| students.size > 1 }

        double_enrollments.each do |course, students|
          csv << [format_names(user), format_names(course.teachers), course.profile.school.name]

          double_enrollments_array << students
        end
      end
    end

    double_enrollments_array.each do |students|
      roles = students.map(&:role)

      # Fix taskings that were given to the wrong role
      all_taskings = roles.flat_map(&:taskings)
      all_taskings.each do |tasking|
        # Active role is the newest role that existed at the time the tasking was created
        existing_roles = roles.select{ |role| role.created_at < tasking.created_at }
        active_role = existing_roles.max_by(&:created_at)
        tasking.role = active_role

        # The period should come from the enrollment that was active when the tasking was created
        existing_enrollments = active_role.student.enrollments.select do |enrollment|
          enrollment.created_at < tasking.created_at
        end
        active_enrollment = existing_enrollments.max_by(&:created_at)
        tasking.period = active_enrollment.period

        concept_coach_task = tasking.task.concept_coach_task
        concept_coach_task.role = tasking.role if concept_coach_task.present?

        if real_run
          tasking.save!
          concept_coach_task.save! if concept_coach_task.present?
        end
      end

      active_role = roles.max_by(&:created_at)
      (roles - [active_role]).each do |old_role|
        role_user = old_role.role_user

        role_user.destroy if real_run
      end
    end
  end
end

private

def format_names(users)
  [users].flatten.map{ |user| user.name.strip }.uniq.sort.join('; ')
end
