namespace :biglearn do
  desc 'Transfers tutor-server data to a new empty Biglearn instance'
  # Shutdown the app servers and any workers before running this
  task initialize: :environment do

    print_each("Creating #{Content::Models::Ecosystem.count} content ecosystems",
               Content::Models::Ecosystem.find_each) do |ecosystem|
      OpenStax::Biglearn::Api.create_ecosystem ecosystem: ecosystem
    end

    print 'Sending global exercise exclusions'

    OpenStax::Biglearn::Api.update_global_exercise_exclusions(
      exercise_ids: Settings::Exercises.excluded_ids
    )

    print ".\n"

    preparation_uuids = []

    courses = Entity::Course.joins(:ecosystems).preload(:ecosystems).uniq.to_a

    print_each("Creating #{courses.length} courses", courses) do |course|
      ecosystems = course.ecosystems.reverse

      first_ecosystem = ecosystems.first

      OpenStax::Biglearn::Api.create_course course: course, ecosystem: first_ecosystem

      (ecosystems - [first_ecosystem]).each do |ecosystem|
        preparation_uuids << OpenStax::Biglearn::Api.prepare_course_ecosystem(
          course: course, ecosystem: ecosystem
        )
      end

      OpenStax::Biglearn::Api.update_course_exercise_exclusions course: course
    end

    requests = courses.map{ |course| { course: course, lock: false } }
    OpenStax::Biglearn::Api.update_rosters requests

    requests = preparation_uuids.map{ |preparation_uuid| { preparation_uuid: preparation_uuid } }
    OpenStax::Biglearn::Api.update_course_ecosystems requests

    print_each("Creating #{Tasks::Models::TaskPlan.count} assignment plans",
               Tasks::Models::TaskPlan.preload(:tasks).find_each) do |task_plan|
      requests = task_plan.tasks.map{ |task| { task: task, lock: false } }
      OpenStax::Biglearn::Api.create_update_assignments requests
    end

    puts 'Biglearn data transfer successful!'

  end
end

def print_each(msg, iter, &block)
  print msg

  iter.map do |ii|
    block.call(ii).tap{ print '.' }
  end.tap{ print "\n" }
end
