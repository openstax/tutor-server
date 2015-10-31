module Salesforce
  module Models
    class CourseClassSize < Tutor::SubSystems::BaseModel
      belongs_to :course, subsystem: :entity

      validates :course, presence: true, uniqueness: true
      validates :class_size_id, presence: true
    end
  end
end
