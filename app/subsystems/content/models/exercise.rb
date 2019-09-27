class Content::Models::Exercise < IndestructibleRecord

  attr_accessor :pool_types, :is_excluded

  wrapped_by ::Content::Strategies::Direct::Exercise

  acts_as_resource

  belongs_to :page, inverse_of: :exercises
  has_one :chapter, through: :page
  has_one :book, through: :chapter
  has_one :ecosystem, through: :book

  has_many :exercise_tags, dependent: :destroy, inverse_of: :exercise
  has_many :tags, through: :exercise_tags

  has_many :tasked_exercises, subsystem: :tasks, dependent: :destroy, inverse_of: :exercise

  validates :uuid, presence: true
  validates :group_uuid, presence: true
  validates :number, presence: true
  validates :version, presence: true

  # http://stackoverflow.com/a/7745635
  scope :latest, ->(scope = unscoped) do
    ex = arel_table
    lv = ex.alias(:later_version)

    where.not(
      scope
        .select(1)
        .from(lv)
        .where(
          lv[:number].eq(ex[:number]).and(
            lv[:version].gt(ex[:version])
          )
        ).arel.exists
    )
  end

  def uid
    "#{number}@#{version}"
  end

  def los
    tags.filter(&:lo?)
  end

  def aplos
    tags.filter(&:aplo?)
  end

  def cnxmods
    tags.filter(&:cnxmod?)
  end

  def cnxfeatures
    tags.filter(&:cnxfeature?)
  end

  def requires_context?
    tags.to_a.any?(&:requires_context?)
  end

  def content_hash
    @content_hash ||= JSON.parse(content)
  end

  def content_as_independent_questions
    @content_as_independent_questions ||= begin
      exercise_hash = content_hash
      questions = exercise_hash['questions']
      questions.map do |question|
        content = exercise_hash.merge('questions' => [question]).to_json

        { id: question['id'], content: content }
      end
    end
  end

  def questions_hash
    content_hash['questions']
  end

  def number_of_parts
    questions_hash.size
  end

  def is_multipart?
    number_of_parts > 1
  end

  def feature_ids
    cnxfeatures.map(&:data)
  end

end
