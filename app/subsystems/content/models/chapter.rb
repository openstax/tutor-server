class Content::Models::Chapter < Tutor::SubSystems::BaseModel

  wrapped_by ::Ecosystem::Strategies::Direct::Chapter

  acts_as_resource

  serialize :book_location, Array
  serialize :toc_cache, Hash
  serialize :page_data_cache, Array

  sortable_belongs_to :book, on: :number, inverse_of: :chapters

  sortable_has_many :pages, on: :number, dependent: :destroy, inverse_of: :chapter

  validates :title, presence: true
  validates :book, presence: true

end
