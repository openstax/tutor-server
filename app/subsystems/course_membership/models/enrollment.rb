class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  belongs_to :period, -> { with_deleted }, inverse_of: :enrollments
  belongs_to :student, -> { with_deleted }, inverse_of: :enrollments

  has_one :enrollment_change, -> { with_deleted }, dependent: :destroy, inverse_of: :enrollment

  validates :period, presence: true
  validates :student, presence: true
  validate :same_course

  default_scope -> { order(:created_at) }

  def self.latest_join_sql(from_association, to_association)
    from_underscored = "course_membership_#{from_association.to_s.chomp('s')}"
    to_underscored = "course_membership_#{to_association.to_s.chomp('s')}"

    <<-SQL
      CROSS JOIN LATERAL (#{
        CourseMembership::Models::Enrollment.where(
          "\"#{from_underscored}_id\" = \"#{from_underscored}s\".\"id\""
        ).reorder(created_at: :desc).limit(1).to_sql
      }) "course_membership_enrollments"
      INNER JOIN "#{to_underscored}s"
        ON "#{to_underscored}s"."id" = "course_membership_enrollments"."#{to_underscored}_id"
    SQL
  end

  scope :latest, -> do
    joins do
      CourseMembership::Models::Enrollment.unscoped.as(:newer_enrollment).on do
        (newer_enrollment.course_membership_student_id == ~course_membership_student_id) & \
        (newer_enrollment.created_at > ~created_at)
      end.outer
    end.where(newer_enrollment: {id: nil})
  end

  protected

  def same_course
    return if student.nil? || period.nil? || student.course == period.course
    errors.add(:base, 'must have a student and a period that belong to the same course')
    false
  end

end
