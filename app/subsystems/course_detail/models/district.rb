module CourseDetail
  module Models
    class District < Tutor::SubSystems::BaseModel
      has_many :schools, subsystem: :course_detail

      validates :name, presence: true, uniqueness: true
    end
  end
end
