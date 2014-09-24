class Klass < ActiveRecord::Base
  belongs_to :course
  has_many :sections, dependent: :destroy
  has_many :educators, dependent: :destroy
  has_many :students, dependent: :destroy

  validates :course, presence: true
end
