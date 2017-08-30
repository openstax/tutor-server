module Lms
  module Models
    class ToolConsumer < Tutor::SubSystems::BaseModel
      # In LTI-speak, the ToolConsumer is the LMS.  We have this record mostly
      # as a way to keep track of Contexts and to record metadata about the LMS.

      has_many :contexts, subsystem: :lms, dependent: :destroy

      # Prevent destroys for the time being
      before_destroy -> { false }
    end
  end
end
