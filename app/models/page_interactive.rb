class PageInteractive < ActiveRecord::Base
  sortable_belongs_to :page, on: :number, inverse_of: :page_interactives
  belongs_to :interactive

  validates :page, presence: true
  validates :interactive, presence: true, uniqueness: { scope: :page_id }
end
