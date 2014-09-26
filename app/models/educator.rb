class Educator < ActiveRecord::Base
  belongs_to :user
  belongs_to :klass

  validates :user, presence: true
  validates :klass, presence: true,
                    uniqueness: { scope: :user_id }
end
