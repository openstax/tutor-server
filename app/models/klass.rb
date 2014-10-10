class Klass < ActiveRecord::Base
  belongs_to :course
  has_one :school, through: :course

  has_many :sections, dependent: :destroy
  has_many :educators, dependent: :destroy
  has_many :students, dependent: :destroy

  validates :course, presence: true
  validates :time_zone, allow_nil: true,
                        inclusion: { in: ActiveSupport::TimeZone.all.map(&:to_s) }

  scope :visible_for, lambda { |user|
    user = user.human_user if user.is_a?(OpenStax::Api::ApiUser)
    next all if user.is_a?(User) && user.administrator
    current_time = Time.now
    where{(visible_at.lt current_time) & (invisible_at.gt current_time)}
  }

end
