namespace :biglearn do
  desc 'Transfers tutor-server data to a new empty Biglearn instance'
  # Shutdown the app servers and any workers before running this
  task initialize: :environment do |task|
    task.extend OpenStax::Biglearn::Locks

    ActiveRecord::Base.transaction do
      ecosystem_ids = Content::Models::Ecosystem.pluck(:id)
      course_ids = CourseProfile::Models::Course.pluck(:id)

      task.with_biglearn_locks(model_class: Content::Models::Ecosystem, model_ids: ecosystem_ids) do
        task.with_biglearn_locks(model_class: CourseProfile::Models::Course,
                                 model_ids: course_ids) do
          Content::Models::Ecosystem.where(id: ecosystem_ids).update_all(sequence_number: 0)
          CourseProfile::Models::Course.where(id: course_ids).update_all(sequence_number: 0)
          puts 'Ecosystem and Course sequence numbers reset.'

          print_each("Creating #{Content::Models::Ecosystem.count} ecosystem(s)",
                     Content::Models::Ecosystem.where(id: ecosystem_ids).find_each) do |ecosystem|
            OpenStax::Biglearn::Api.create_ecosystem ecosystem: ecosystem
          end

          courses = CourseProfile::Models::Course.where(id: course_ids)
                                                 .joins(:ecosystems)
                                                 .preload(:ecosystems)
                                                 .uniq

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

              next if course.periods_with_deleted.empty?

              roster_updates << { course: course }
            end

            OpenStax::Biglearn::Api.update_rosters roster_updates

            OpenStax::Biglearn::Api.update_course_ecosystems ecosystem_updates
          end

          print_each("Creating #{Tasks::Models::Task.count} assignment(s)",
                     Tasks::Models::Task.preload(taskings: { role: { student: :course } })
                                        .find_in_batches) do |tasks|
            requests = tasks.map do |task|
              course = task.taskings.first.try!(:role).try!(:student).try!(:course)
              # Skip weird cases like deleted students and preview assignments
              next if course.nil?

              { course: course, task: task }
            end.compact

            OpenStax::Biglearn::Api.create_update_assignments requests
          end

          answered_exercises = Tasks::Models::TaskedExercise
                                 .joins(:task_step)
                                 .where{task_step.first_completed_at != nil}
          print_each("Creating #{answered_exercises.count} response(s)",
                     answered_exercises
                       .preload(task_step: { task: { taskings: { role: { student: :course } } } })
                       .find_in_batches) do |tasked_exercises|
            requests = tasked_exercises.map do |tasked_exercise|
              course = tasked_exercise.task_step.task.taskings.first
                                      .try!(:role).try!(:student).try!(:course)
              # Skip weird cases like deleted students and preview assignments
              next if course.nil?

              { course: course, tasked_exercise: tasked_exercise }
            end.compact

            OpenStax::Biglearn::Api.record_responses requests
          end

          puts 'Biglearn data transfer successful! (or background jobs created)'
        end
      end
    end
  end
end

def print_each(msg, iter, &block)
  print msg

  iter.map { |ii| block.call(ii).tap{ print '.' } }.tap{ print "\n" }
end
