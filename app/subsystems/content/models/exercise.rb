class Content::Models::Exercise < Tutor::SubSystems::BaseModel

  attr_accessor :pool_types, :is_excluded

  acts_as_resource

  wrapped_by ::Content::Strategies::Direct::Exercise

  belongs_to :page, inverse_of: :exercises
  has_one :chapter, through: :page
  has_one :book, through: :chapter
  has_one :ecosystem, through: :book

  has_many :exercise_tags, dependent: :destroy, inverse_of: :exercise
  has_many :tags, through: :exercise_tags

  has_many :tasked_exercises, subsystem: :tasks, dependent: :destroy, inverse_of: :exercise

  validates :uuid, presence: true
  validates :number, presence: true
  validates :version, presence: true

  # http://stackoverflow.com/a/7745635
  scope :latest, ->(scope = unscoped) {
    joins do
      scope.as(:later_version).on do
        (later_version.number == ~number) & (later_version.version > ~version)
      end.outer
    end.where{later_version.id == nil}
  }

  def uid
    "#{number}@#{version}"
  end

  def los
    tags.to_a.select(&:lo?)
  end

  def aplos
    tags.to_a.select(&:aplo?)
  end

  def cnxmods
    tags.to_a.select(&:cnxmod?)
  end

  def cnxfeatures
    tags.to_a.select(&:cnxfeature?)
  end

  def content_hash
    ::JSON.parse(content)
  end

  def content_as_independent_questions
    @content_as_independent_questions ||= begin
      exercise_hash = content_hash
      questions = exercise_hash['questions']
      questions.map do |question|
        content = exercise_hash.merge('questions' => [question]).to_json
        {id: question['id'], content: content}
      end
    end
  end

  def requires_context?
    tags.to_a.any?(&:requires_context?)
  end

  def is_multipart?
    content_hash['questions'].size > 1
  end

  def feature_ids
    cnxfeatures.map(&:data)
  end

end
