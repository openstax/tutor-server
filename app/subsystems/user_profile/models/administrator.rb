class UserProfile::Models::Administrator < ActiveRecord::Base
  belongs_to :profile, inverse_of: :administrator, class_name: 'UserProfile::Models::Profile'

  # has_many :tasking_plans, as: :target, dependent: :destroy
  # has_many :taskings, as: :taskee, dependent: :destroy

  validates :profile, presence: true, uniqueness: true
end
