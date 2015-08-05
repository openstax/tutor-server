class Content::Models::Chapter < Tutor::SubSystems::BaseModel

  wrapped_by ::Ecosystem::Strategies::Direct::Chapter

  serialize :book_location, Array

  sortable_belongs_to :book, on: :number, inverse_of: :chapters

  sortable_has_many :pages, on: :number, dependent: :destroy, autosave: true, inverse_of: :chapter

  validates :book, presence: true
  validates :title, presence: true

end
