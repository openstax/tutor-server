# Performs all demo routines (except Users and Show) in succession
class Demo::All < Demo::Base
  lev_routine

  # The input translations are really error translations
  uses_routine Demo::Users,  as: :users,  translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Import, as: :import, translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Course, as: :course, translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Assign, as: :assign, translations: { inputs: { type: :verbatim } }
  uses_routine Demo::Work

  protected

  def exec(users:, import:, course:, assign:, work:)
    run :users, users: users
    catalog_offering = run(:import, import: import).outputs.catalog_offering
    course[:catalog_offering] ||= {}
    course[:catalog_offering][:id] = catalog_offering.id
    course = run(:course, course: course).outputs.course
    assign[:course] ||= {}
    assign[:course][:id] = course.id
    run :assign, assign: assign
    work[:course] ||= {}
    work[:course][:id] = course.id

    # Work always happens in a separate transaction because we need the assignments
    # to be sent to Biglearn so the placeholder steps can be populated when working
    Demo::Work.perform_later work: work

    log_status course.name
  end
end
