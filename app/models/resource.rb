class Resource < ActiveRecord::Base

  has_one :reading, dependent: :destroy
  has_one :exercise, dependent: :destroy
  has_one :interactive, dependent: :destroy

  validates :url, presence: true, uniqueness: true

end
