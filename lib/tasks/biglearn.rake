namespace :biglearn do
  desc 'Transfers tutor-server data to a new empty Biglearn instance'
  # Shutdown the app servers and any workers before running this
  task initialize: :environment do

    print_each("Creating #{Content::Models::Ecosystem.count} ecosystems",
               Content::Models::Ecosystem.find_each) do |ecosystem|
      OpenStax::Biglearn::Api.create_ecosystem ecosystem: ecosystem
    end

    ecosystem_updates = []

    courses = CourseProfile::Models::Course.joins(:ecosystems).preload(:ecosystems).uniq.to_a

    print_each("Creating #{courses.length} courses", courses) do |course|
      ecosystems = course.ecosystems.reverse

      OpenStax::Biglearn::Api.create_course course: course, ecosystem: ecosystems.first

      OpenStax::Biglearn::Api.update_global_exercise_exclusions course: course

      OpenStax::Biglearn::Api.update_course_exercise_exclusions course: course

      (ecosystems.slice(1..-1)).each do |ecosystem|
        preparation_uuid = OpenStax::Biglearn::Api.prepare_course_ecosystem(
          course: course, ecosystem: ecosystem
        )

        ecosystem_updates << { course: course, preparation_uuid: preparation_uuid }
      end
    end

    requests = courses.map{ |course| { course: course } }
    OpenStax::Biglearn::Api.update_rosters requests

    OpenStax::Biglearn::Api.update_course_ecosystems ecosystem_updates

    print_each("Creating #{Tasks::Models::TaskPlan.count} assignment plans",
               Tasks::Models::TaskPlan.preload(:tasks).find_each) do |task_plan|
      requests = task_plan.tasks.map{ |task| { course: task_plan.owner, task: task } }
      OpenStax::Biglearn::Api.create_update_assignments requests
    end

    # TODO: CC/practice tasks

    # TODO: Responses

    puts 'Biglearn data transfer successful!'

  end
end

def print_each(msg, iter, &block)
  print msg

  iter.map do |ii|
    block.call(ii).tap{ print '.' }
  end.tap{ print "\n" }
end
