class Content::Models::Book < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Book

  acts_as_resource

  auto_uuid :tutor_uuid

  json_serialize :reading_processing_instructions, Hash, array: true

  belongs_to :ecosystem, inverse_of: :books

  sortable_has_many :chapters, on: :number, dependent: :destroy, inverse_of: :book
  # If you need the pages in order, you MUST iterate through the chapters
  has_many :pages, through: :chapters
  has_many :exercises, through: :pages

  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  scope :preloaded, ->{ preload(chapters: :pages) }

  def archive_url
    Addressable::URI.parse(url).site
  end

  def webview_url
    archive_url.sub(/archive[\.-]?/, '')
  end

  def cnx_id
    "#{uuid}@#{version}"
  end

  def manifest_hash
    {
      archive_url: archive_url,
      cnx_id: cnx_id,
      reading_processing_instructions: reading_processing_instructions,
      exercise_ids: exercises.sort_by(&:number).map(&:uid)
    }
  end

end
