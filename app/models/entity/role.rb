module Entity
  class Role < IndestructibleRecord
    enum role_type: [:unassigned, :default, :teacher, :student, :teacher_student]

    has_many :taskings, subsystem: :tasks, dependent: :destroy, inverse_of: :role

    has_one :student, dependent: :destroy, subsystem: :course_membership, inverse_of: :role
    has_one :teacher, dependent: :destroy, subsystem: :course_membership, inverse_of: :role
    has_one :teacher_student, dependent: :destroy, subsystem: :course_membership, inverse_of: :role

    belongs_to :profile, subsystem: :user, inverse_of: :roles

    delegate :username, :first_name, :last_name, :full_name, :name, to: :profile, allow_nil: true

    unique_token :research_identifier, mode: :hex, length: 4, prefix: 'r'

    def latest_enrollment_at
      student.try!(:latest_enrollment).try!(:created_at)
    end
  end
end
