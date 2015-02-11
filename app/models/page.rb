class Page < ActiveRecord::Base
  belongs_to_resource

  sortable_belongs_to :book, on: :number, inverse_of: :pages

  has_many :page_topics, dependent: :destroy

  validates :resource, presence: true
  validates :title, presence: true
end
