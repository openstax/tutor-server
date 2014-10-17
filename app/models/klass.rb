class Klass < ActiveRecord::Base
  belongs_to :course
  has_one :school, through: :course

  has_many :sections, dependent: :destroy
  has_many :educators, dependent: :destroy
  has_many :students, dependent: :destroy

  validates :course, presence: true
  validates :time_zone, allow_nil: true,
                        inclusion: { in: ActiveSupport::TimeZone.all.map(&:to_s) }
end
