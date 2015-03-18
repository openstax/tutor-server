class Educator < ActiveRecord::Base
  belongs_to :user, class_name: 'UserProfile::Profile'
  belongs_to :course

  has_many :tasking_plans, as: :target, dependent: :destroy
  has_many :taskings, as: :taskee, dependent: :destroy

  validates :user, presence: true
  validates :course, presence: true,
                     uniqueness: { scope: :user_id }
end
