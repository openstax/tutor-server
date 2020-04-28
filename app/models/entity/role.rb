module Entity
  class Role < IndestructibleRecord
    enum role_type: [:unassigned, :default, :teacher, :student, :teacher_student]

    has_one :student, dependent: :destroy, subsystem: :course_membership, inverse_of: :role
    has_one :teacher, dependent: :destroy, subsystem: :course_membership, inverse_of: :role
    has_one :teacher_student, dependent: :destroy, subsystem: :course_membership, inverse_of: :role

    has_many :taskings, subsystem: :tasks, dependent: :destroy, inverse_of: :role

    has_many :notes, subsystem: :content, dependent: :destroy, inverse_of: :role

    has_many :role_book_parts, subsystem: :cache, dependent: :destroy, inverse_of: :role

    belongs_to :profile, subsystem: :user, inverse_of: :roles

    delegate :username, :first_name, :last_name, :full_name, :title, :name, :is_test,
             to: :profile, allow_nil: true
    delegate :course, :period, :course_profile_course_id, to: :course_member, allow_nil: true

    unique_token :research_identifier, mode: :hex, length: 4, prefix: 'r'

    def course_member
      case role_type
      when 'teacher'
        teacher
      when 'teacher_student'
        teacher_student
      when 'student'
        student
      end
    end

    def latest_enrollment_at
      return unless student?

      student.latest_enrollment_at
    end
  end
end
