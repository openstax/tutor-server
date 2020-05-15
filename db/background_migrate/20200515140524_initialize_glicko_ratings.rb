class InitializeGlickoRatings < ActiveRecord::Migration[5.2]
  include Ratings::Concerns::RatingJobs

  LIMIT = 1000

  def up
    current_time = Time.current

    offset = 0
    tasks = Tasks::Models::Task.preload(
      taskings: { role: [ { student: :period }, { teacher_student: :period } ] }
    ).order(:due_at_ntz).limit(LIMIT)

    until tasks.empty?
      tasks = Tasks::Models::Task.preload(
        taskings: { role: [ { student: :period }, { teacher_student: :period } ] }
      ).order(:due_at_ntz).offset(offset).first(LIMIT)
      offset += tasks.size

      tasks.each do |task|
        role = task.taskings.first.role
        period = role.course_member.period

        perform_rating_jobs_later(
          task: task,
          role: role,
          period: period,
          current_time: current_time,
          queue: 'migration'
        )
      end
    end
  end

  def down
  end
end
