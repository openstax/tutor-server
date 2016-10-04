namespace :biglearn do
  desc 'Transfers tutor-server data to a new empty Biglearn instance'
  # Shutdown the app and workers before running this
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

    print_each("Creating #{Entity::Course.count} courses",
               Entity::Course.preload(:ecosystems).find_each) do |course|
      ecosystems = course.ecosystems.reverse

      first_ecosystem = ecosystems.first

      OpenStax::Biglearn::Api.create_course course: course, ecosystem: first_ecosystem

      (ecosystems - [first_ecosystem]).each do |ecosystem|
        preparation_uuid = OpenStax::Biglearn::Api.prepare_course_ecosystem course: course,
                                                                            ecosystem: ecosystem
        OpenStax::Biglearn::Api.update_course_ecosystems preparation_uuid: preparation_uuid
      end

      OpenStax::Biglearn::Api.update_course_exercise_exclusions course: course

      OpenStax::Biglearn::Api.update_rosters course: course, lock: false
    end

    print_each("Creating #{Tasks::Models::Task.count} tasks",
               Tasks::Models::Task.find_each) do |task|
      OpenStax::Biglearn::Api.create_update_assignments task: task, lock: false
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
