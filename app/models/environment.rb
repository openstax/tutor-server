class Environment < IndestructibleRecord
  has_many :courses, subsystem: :course_profile, inverse_of: :environment

  validates :name, presence: true, uniqueness: true

  def self.current
    find_or_create_by! name: Rails.application.secrets.environment_name
  end

  def current?
    name == Rails.application.secrets.environment_name
  end
end
