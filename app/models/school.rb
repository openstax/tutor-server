class School < ActiveRecord::Base
  has_many :school_managers, dependent: :destroy
  has_many :courses, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }
end
