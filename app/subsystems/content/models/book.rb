class Content::Models::Book < Tutor::SubSystems::BaseModel

  wrapped_by ::Ecosystem::Strategies::Direct::Book

  acts_as_resource

  belongs_to :ecosystem, inverse_of: :books

  has_many :chapters, dependent: :destroy, autosave: true, inverse_of: :book
  has_many :pages, through: :chapters
  has_many :exercises, through: :pages

  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  def cnx_id
    "#{uuid}@#{version}"
  end

end

