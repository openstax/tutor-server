class School < ActiveRecord::Base
  has_many :school_managers, dependent: :destroy
  has_many :courses, dependent: :destroy

  has_many :course_managers, through: :courses
  has_many :klasses, through: :courses
  has_many :students, through: :klasses
  has_many :educators, through: :klasses

  has_many :tasking_plans, as: :target, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }
  validates :default_time_zone, allow_nil: true,
                                inclusion: { in: ActiveSupport::TimeZone.all.map(&:to_s) }
end
