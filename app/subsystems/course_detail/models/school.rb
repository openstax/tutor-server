module CourseDetail
  module Models
    class School < Tutor::SubSystems::BaseModel
      belongs_to :district, class_name: 'CourseDetail::Models::District'

      validates :name, presence: true, uniqueness: { scope: :course_detail_district_id }
    end
  end
end
