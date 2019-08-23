# Performs all demo routines (except Users and Show) in succession
class Demo::All < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  # The input translations are really error translations
  uses_routine Demo::Users,  as: :users,  translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Import, as: :import, translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Course, as: :course, translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Assign, as: :assign, translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Work

  protected

  def exec(users: nil, import: nil, course: nil, assign: nil, work: nil)
    run :users, users: users unless users.nil?

    unless import.nil?
      catalog_offering = run(:import, import: import).outputs.catalog_offering

      unless course.nil?
        course[:catalog_offering] ||= {}
        course[:catalog_offering][:id] = catalog_offering.id
      end
    end

    unless course.nil?
      course = run(:course, course: course).outputs.course

      unless assign.nil?
        assign[:course] ||= {}
        assign[:course][:id] = course.id
      end

      unless work.nil?
        work[:course] ||= {}
        work[:course][:id] = course.id
      end
    end

    run :assign, assign: assign unless assign.nil?

    # Work always happens in a separate transaction because we need the assignments
    # to be sent to Biglearn so the placeholder steps can be populated when working
    Demo::Work.perform_later work: work unless work.nil?

    log_status course&.name
  end
end
