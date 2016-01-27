module CustomerService
  class StatsController < BaseController
    include Manager::StatsActions

    self.course_url_proc = ->(course) { customer_service_course_path(course.id) }
  end
end
