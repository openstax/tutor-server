namespace :biglearn do
  desc 'Transfers tutor-server data to a new empty Biglearn instance'
  # Shutdown the app servers and any workers before running this
  task initialize: :environment do |task|
    args = ActiveRecord::Base.connection.open_transactions == 0 ? { isolation: :repeatable_read } :
                                                                  {}

    ActiveRecord::Base.transaction(args) do
      ecosystem_ids = Content::Models::Ecosystem.pluck(:id)
      course_ids = CourseProfile::Models::Course.pluck(:id)

      Content::Models::Ecosystem.where(id: ecosystem_ids).update_all(sequence_number: 0)
      CourseProfile::Models::Course.where(id: course_ids).update_all(sequence_number: 0)
      puts 'Ecosystem and Course sequence numbers reset.'

      print_each("Creating #{Content::Models::Ecosystem.count} ecosystem(s)",
                 Content::Models::Ecosystem.where(id: ecosystem_ids).find_each) do |ecosystem|
        OpenStax::Biglearn::Api.create_ecosystem ecosystem: ecosystem
      end

      courses = CourseProfile::Models::Course
        .where(id: course_ids)
        .joins(:ecosystems)
        .preload(
          :ecosystems, periods: { latest_enrollments: :student }
        ).distinct

      print_each("Creating #{courses.count} course(s)", courses.find_in_batches) do |courses|
        roster_updates = []
        ecosystem_updates = []
        courses.each do |course|
          ecosystems = course.ecosystems.reverse

          OpenStax::Biglearn::Api.create_course course: course, ecosystem: ecosystems.first

          OpenStax::Biglearn::Api.update_globally_excluded_exercises course: course

          OpenStax::Biglearn::Api.update_course_excluded_exercises course: course

          (ecosystems[1..-1]).each do |ecosystem|
            preparation_hash = OpenStax::Biglearn::Api.prepare_course_ecosystem(
              course: course, ecosystem: ecosystem
            )

            ecosystem_updates << preparation_hash.merge(course: course)
          end

          next if course.periods.empty?

          roster_updates << { course: course }
        end

        OpenStax::Biglearn::Api.update_rosters roster_updates

        OpenStax::Biglearn::Api.update_course_ecosystems ecosystem_updates
      end

      print_each("Creating #{Tasks::Models::Task.count} assignment(s)",
                 Tasks::Models::Task.select([:id, :content_ecosystem_id])
                                    .preload(:ecosystem, taskings: { role: { student: :course } })
                                    .find_in_batches) do |tasks|
        requests = tasks.map do |task|
          course = task.taskings.first.try!(:role).try!(:student).try!(:course)
          # Skip weird cases like deleted students and preview assignments
          next if course.nil?

          { course: course, task: task }
        end.compact

        OpenStax::Biglearn::Api.create_update_assignments requests
      end

      co = CourseProfile::Models::Course.arel_table
      tk = Tasks::Models::Tasking.arel_table
      answered_exercise_steps = Tasks::Models::TaskStep
                                  .where(tasked_type: 'Tasks::Models::TaskedExercise')
                                  .where{first_completed_at != nil}
                                  .select([:id, :tasked_id, :tasks_task_id])

      print_each("Creating #{answered_exercise_steps.count} response(s)",
                 answered_exercise_steps.find_in_batches) do |answered_exercise_steps|
        task_ids = answered_exercise_steps.map(&:tasks_task_id)
        courses_by_task_id = CourseProfile::Models::Course
          .select([ co[:id], tk[:tasks_task_id] ])
          .joins(students: { role: :taskings })
          .where(students: { role: { taskings: { tasks_task_id: task_ids } } })
          .index_by(&:tasks_task_id)

        tasked_exercise_ids = answered_exercise_steps.map(&:tasked_id)
        tasked_exercises_by_id = Tasks::Models::TaskedExercise
          .select(:id)
          .where(id: tasked_exercise_ids)
          .index_by(&:id)

        requests = answered_exercise_steps.map do |answered_exercise_step|
          course = courses_by_task_id[answered_exercise_step.tasks_task_id]
          tasked_exercise = tasked_exercises_by_id[answered_exercise_step.tasked_id]
          # Skip any bad data
          next if course.nil? || tasked_exercise.nil?

          { course: course, tasked_exercise: tasked_exercise }
        end.compact

        OpenStax::Biglearn::Api.record_responses requests
      end

      puts 'Biglearn data transfer successful! (or background jobs created)'
    end
  end
end

def print_each(msg, iter, &block)
  print msg

  iter.each { |ii| block.call(ii).tap { print '.' } }.tap { print "\n" }
end
