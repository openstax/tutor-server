class Content::Page < ActiveRecord::Base
  acts_as_resource

  sortable_belongs_to :book_part, on: :number, inverse_of: :pages

  has_many :page_tags, dependent: :destroy

  validates :title, presence: true

end
