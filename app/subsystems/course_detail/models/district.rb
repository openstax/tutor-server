module CourseDetail
  module Models
    class District < Tutor::SubSystems::BaseModel
      validates :name, presence: true, uniqueness: true
    end
  end
end
