class Section < ActiveRecord::Base
  belongs_to :klass
  has_many :students, dependent: :nullify

  validates :klass, presence: true
  validates :name, presence: true, uniqueness: { scope: :klass_id }
end
