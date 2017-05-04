class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  belongs_to :period, -> { with_deleted }
  belongs_to :student, -> { with_deleted }

  has_one :enrollment_change, -> { with_deleted }, dependent: :destroy

  validates :period, presence: true
  validates :student, presence: true
  validate :same_course

  default_scope -> { order(:created_at) }

  def self.with_reverse_sequence_number_sql
    <<-SQL
      (
        SELECT course_membership_enrollments.*,
          row_number() OVER (
            PARTITION BY course_membership_enrollments.course_membership_student_id
            ORDER BY course_membership_enrollments.created_at DESC
          ) AS reverse_sequence_number
        FROM course_membership_enrollments
      ) AS course_membership_enrollments
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
