class Content::Models::Book < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Book

  acts_as_resource

  belongs_to :ecosystem, inverse_of: :books

  sortable_has_many :chapters, on: :number, dependent: :destroy, autosave: true, inverse_of: :book
  has_many :pages, through: :chapters
  has_many :exercises, through: :pages

  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  def archive_url
    Addressable::URI.parse(url).site
  end

  def cnx_id
    "#{uuid}@#{version}"
  end

  def reading_features_hash
    {
      reading_features: attributes.slice(
        'reading_split_css', 'video_split_css', 'interactive_split_css',
        'required_exercise_css', 'optional_exercise_css', 'discard_css'
      ).symbolize_keys
    }
  end

  def manifest_hash
    book_hash = { archive_url: archive_url, cnx_id: cnx_id }
    exercises_hash = { exercise_ids: exercises.map(&:uid).sort }

    # Craft the hash key order for readability purposes
    book_hash.merge(reading_features_hash).merge(exercises_hash)
  end

end
