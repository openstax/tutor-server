class CourseManager < ActiveRecord::Base
  belongs_to :user
  belongs_to :course

  validates :user, presence: true
  validates :course, presence: true,
                     uniqueness: { scope: :user_id }
end
