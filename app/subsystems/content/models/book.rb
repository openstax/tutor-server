class Content::Models::Book < IndestructibleRecord
  acts_as_resource

  auto_uuid :tutor_uuid

  json_serialize :reading_processing_instructions, Hash, array: true

  belongs_to :ecosystem, inverse_of: :books

  # If you need the pages in order, use the children method to obtain the book tree
  # or sort using the book_location
  has_many :pages, dependent: :destroy, inverse_of: :book
  has_many :exercises, through: :pages

  validates :ecosystem, presence: true
  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true
  validates :url, presence: true

  scope :preloaded, -> { preload :pages }

  after_create :set_ecosystem_title

  delegate :children, :units, :chapters, *Content::Models::Page::EXERCISE_ID_FIELDS, to: :as_toc

  def type
    'Book'
  end

  def book_location
    []
  end

  def as_toc
    @as_toc ||= Content::Book.new(tree)
  end

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

  def set_ecosystem_title
    ecosystem.books.reload unless ecosystem.books.include?(self)
    ecosystem.update_attribute :title, ecosystem.set_title
  end

  def reference_view_url
    raise('Unpersisted Ecosystem') if ecosystem.id.nil?

    "/book/#{ecosystem.id}"
  end
end
