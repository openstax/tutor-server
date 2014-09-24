class SchoolManager < ActiveRecord::Base
  belongs_to :user
  belongs_to :school

  validates :user, presence: true
  validates :school, presence: true,
                     uniqueness: { scope: :user_id }
end
