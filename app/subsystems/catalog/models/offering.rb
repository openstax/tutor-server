class Catalog::Models::Offering < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  sortable_class on: :number

  belongs_to :ecosystem, subsystem: :content

  has_many :courses, subsystem: :course_profile

  validates :salesforce_book_name,  presence: true
  validates :title, presence: true
  validates :description, presence: true

  validate :preview_must_be_available

  def preview_must_be_available
    if is_available && !is_preview_available
      errors.add(:is_preview_available, 'must be true when course is available')
    end
  end
end
