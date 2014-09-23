class Administrator < ActiveRecord::Base

  belongs_to :user, inverse_of: :administrator

  validates :user, presence: true, uniqueness: true

end
