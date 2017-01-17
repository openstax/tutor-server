module Routing
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    def default_url_options
      ActionMailer::Base.default_url_options
    end
  end
end

class UrlGenerator
  include Routing

  def self.teach_course_url(token)
    new.teach_course_url(token, "DO_NOT_GIVE_TO_STUDENTS")
  end

  def self.teacher_task_plan_review(course_id:, due_at:, task_plan_id:)
    new.teacher_task_plan_review_path(course_id, due_at.strftime('%Y-%m-%d'), task_plan_id)
  end

  def self.student_task(course_id:, task_id:)
    new.student_task_path(course_id, task_id)
  end
end
