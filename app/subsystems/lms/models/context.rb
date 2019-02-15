module Lms
  module Models
    class Context < ApplicationRecord
      # Links an LMS-provided "context_id" to a course, so when we receive a launch
      # we know which course it is for.

      belongs_to :tool_consumer
      belongs_to :course, subsystem: :course_profile

      before_destroy :confirm_course_access_is_switchable

      def app
        app_type.constantize.for_course(course)
      end

      protected

      def confirm_course_access_is_switchable
        if course && !course.is_access_switchable?
          errors.add(:course, 'access is not switchable')
        end
      end

    end

  end
end
