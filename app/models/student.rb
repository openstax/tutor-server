class Student < ActiveRecord::Base
  belongs_to :user
  belongs_to :klass
  belongs_to :section
  
  validates :user, presence: true
  validates :klass, presence: true,
                    uniqueness: { scope: :user_id }
  validates :section, allow_nil: true,
                      uniqueness: { scope: :user_id }
end
