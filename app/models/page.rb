class Page < ActiveRecord::Base
  acts_as_resource

  sortable_belongs_to :book, on: :number, inverse_of: :pages

  has_many :page_topics, dependent: :destroy

  validates :title, presence: true
end
