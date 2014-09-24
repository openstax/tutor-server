class Section < ActiveRecord::Base
  belongs_to :klass
  has_many :students, dependent: :nullify

  validates :klass, presence: true
end
