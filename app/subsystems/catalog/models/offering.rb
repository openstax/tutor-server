class Catalog::Models::Offering < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  sortable_class on: :number

  belongs_to :ecosystem, subsystem: :content

  has_many :courses, subsystem: :course_profile

  validates :salesforce_book_name,  presence: true
  validates :webview_url, presence: true
  validates :title, presence: true
  validates :description, presence: true
end
