class Content::Models::Book < Tutor::SubSystems::BaseModel

  wrapped_by ::Ecosystem::Strategies::Direct::Book

  belongs_to :ecosystem

  has_many :chapters, dependent: :destroy
  has_many :pages, through: :chapters
  has_many :exercises, through: :pages

  validates :title, presence: true

end

