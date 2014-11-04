class Educator < ActiveRecord::Base
  belongs_to :user
  belongs_to :klass

  has_many :tasking_plans, as: :target, dependent: :destroy
  has_many :taskings, as: :taskee, dependent: :destroy

  validates :user, presence: true
  validates :klass, presence: true,
                    uniqueness: { scope: :user_id }
end
