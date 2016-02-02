module Admin
  class StatsController < BaseController
    include Manager::StatsActions

    self.course_url_proc = ->(course) { edit_admin_course_path(course.id) }
  end
end
