class Content::Models::Chapter < IndestructibleRecord

  wrapped_by ::Content::Strategies::Direct::Chapter

  auto_uuid :tutor_uuid

  json_serialize :book_location, Integer, array: true
  json_serialize :baked_book_location, Integer, array: true

  belongs_to :all_exercises_pool, class_name: 'Content::Models::Pool',
                                  dependent: :destroy,
                                  optional: true

  sortable_belongs_to :book, on: :number, inverse_of: :chapters
  has_one :ecosystem, through: :book

  sortable_has_many :pages, on: :number, dependent: :destroy, inverse_of: :chapter
  has_many :exercises, through: :pages

  validates :title, presence: true
  validates :book_location, presence: true

end
