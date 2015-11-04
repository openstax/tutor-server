class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  belongs_to :school, subsystem: :school_district
  belongs_to :course, subsystem: :entity

  before_validation :generate_teacher_access_token

  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.collect(&:name) }

  delegate :name, to: :school,
                  prefix: true,
                  allow_nil: true

  private
  def generate_teacher_access_token
    return true unless teacher_access_token.blank?

    begin
      self.teacher_access_token = SecureRandom.hex
    end while self.class.exists?(teacher_access_token: self[:teacher_access_token])
  end
end
