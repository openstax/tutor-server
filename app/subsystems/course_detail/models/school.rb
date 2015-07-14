module CourseDetail
  module Models
    class School < Tutor::SubSystems::BaseModel
      belongs_to :district, class_name: 'CourseDetail::Models::District',
                            foreign_key: 'course_detail_district_id'

      validates :name, presence: true,
                       uniqueness: { scope: :course_detail_district_id }

      delegate :name,
        to: :district,
        prefix: true,
        allow_nil: true
    end
  end
end
