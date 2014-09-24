class School < ActiveRecord::Base
  has_many :school_managers, dependent: :destroy
  has_many :courses, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }
  validates :default_time_zone, allow_nil: true,
                                inclusion: { in: ActiveSupport::TimeZone.all.map(&:to_s) }
end
