module Lms
  module Models
    class Context < Tutor::SubSystems::BaseModel
      # Links an LMS-provided "context_id" to a course, so when we receive a launch
      # we know which course it is for.

      belongs_to :tool_consumer
      belongs_to :course, subsystem: :course_profile
    end
  end
end
