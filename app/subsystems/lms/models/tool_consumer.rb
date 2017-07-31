class Lms::Models::ToolConsumer < IndestructibleRecord
  # In LTI-speak, the ToolConsumer is the LMS.  We have this record mostly
  # as a way to keep track of Contexts and to record metadata about the LMS.

  has_many :contexts, subsystem: :lms, dependent: :destroy

  validates :guid, presence: true, uniqueness: true
end
