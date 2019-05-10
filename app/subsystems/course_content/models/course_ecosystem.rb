class CourseContent::Models::CourseEcosystem < IndestructibleRecord

  belongs_to :course, subsystem: :course_profile
  belongs_to :ecosystem, subsystem: :content

  default_scope -> { order(created_at: :desc) }

end
