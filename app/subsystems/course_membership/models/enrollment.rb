class CourseMembership::Models::Enrollment < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  belongs_to :period, -> { with_deleted }, inverse_of: :enrollments
  belongs_to :student, -> { with_deleted }, inverse_of: :enrollments

  has_one :enrollment_change, -> { with_deleted }, dependent: :destroy, inverse_of: :enrollment

  before_validation :assign_sequence_number

  validates :period, presence: true
  validates :student, presence: true
  validates :sequence_number, presence: true,
                              uniqueness: { scope: :course_membership_student_id },
                              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :same_course

  default_scope -> { order(:sequence_number) }

  scope :latest, -> do
    unscoped.where.not(
      CourseMembership::Models::Enrollment
        .unscoped
        .from('"course_membership_enrollments" "same_student_enrollments"')
        .where(
          <<-SQL.strip_heredoc
            "same_student_enrollments"."course_membership_student_id" =
              "course_membership_enrollments"."course_membership_student_id"
              AND "same_student_enrollments"."sequence_number" >
                "course_membership_enrollments"."sequence_number"
          SQL
        )
        .exists
    )
  end

  def self.latest_join_sql(from_association, to_association)
    from_underscored = "course_membership_#{from_association.to_s.chomp('s')}"
    to_underscored = "course_membership_#{to_association.to_s.chomp('s')}"

    <<-SQL
      INNER JOIN (#{
        CourseMembership::Models::Enrollment.latest.to_sql
      }) "course_membership_enrollments"
        ON "course_membership_enrollments"."#{from_underscored}_id" = "#{from_underscored}s"."id"
      INNER JOIN "#{to_underscored}s"
        ON "#{to_underscored}s"."id" = "course_membership_enrollments"."#{to_underscored}_id"
    SQL
  end

  protected

  def assign_sequence_number
    return if !sequence_number.nil? || student.nil?

    enrollments = student.enrollments
    max_sequence_number = if enrollments.loaded?
      enrollments.map(&:sequence_number).max
    else
      enrollments.maximum(:sequence_number)
    end

    self.sequence_number = (max_sequence_number || 0) + 1
  end

  def same_course
    return if student.nil? || period.nil? || student.course == period.course
    errors.add(:base, 'must have a student and a period that belong to the same course')
    false
  end

end
