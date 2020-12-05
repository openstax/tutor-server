class Content::Models::Exercise < IndestructibleRecord
  acts_as_paranoid without_default_scope: true

  attr_accessor :pool_types, :is_excluded

  acts_as_resource

  belongs_to :page, inverse_of: :exercises
  has_one :book, through: :page
  has_one :ecosystem, through: :book

  belongs_to :derived_from, class_name: 'Content::Models::Exercise', foreign_key: :derived_from_id, optional: true
  has_many :derivatives, class_name: 'Content::Models::Exercise', foreign_key: :derived_from_id

  belongs_to :profile, subsystem: :user, optional: true

  has_many :exercise_tags, dependent: :destroy, inverse_of: :exercise
  has_many :tags, through: :exercise_tags

  has_many :tasked_exercises, subsystem: :tasks, dependent: :destroy, inverse_of: :exercise

  if respond_to?(:has_many_attached)
    has_many_attached :images
  else
    Rails.application.config.after_initialize do
      Content::Models::Exercise.has_many_attached :images
    end
  end

  validates :uuid, presence: true
  validates :group_uuid, presence: true
  validates :number, presence: true
  validates :version, presence: true
  validates :user_profile_id, presence: true

  before_validation :set_teacher_exercise_number, unless: :number?

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
  scope :requires_context, -> do
    where(
      Content::Models::Tag.requires_context.joins(:exercise_tags).where(
        '"content_exercise_tags"."content_exercise_id" = "content_exercises"."id"'
      ).arel.exists
    )
  end

  def parser
    @parser ||= OpenStax::Exercises::V1::Exercise.new content: content
  end

  def units
    books.flat_map(&:units)
  end

  def chapters
    books.flat_map(&:chapters)
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

  def questions_hash
    content_hash['questions']
  end

  def questions
    @questions ||= questions_hash.map do |question|
      Content::Question.new(
        id: question['id'], content_hash: content_hash.merge('questions' => [question])
      )
    end
  end

  def is_multipart?
    number_of_questions > 1
  end

  def is_free_response_only?
    question_answer_ids.any? { |answer_ids| answer_ids.empty? }
  end

  def feature_ids
    cnxfeatures.map(&:data)
  end

  def author
    if user_profile_id == User::Models::OpenStaxProfile::ID
      User::Models::OpenStaxProfile
    elsif anonymize_author
      User::Models::AnonymousAuthorProfile
    else
      User::Models::Profile.find(user_profile_id)
    end
  end

  def authored_by_teacher?
    user_profile_id.present? && user_profile_id != User::Models::OpenStaxProfile::ID
  end

  def set_teacher_exercise_number
    return unless authored_by_teacher?

    self.number = generate_next_teacher_exercise_number
  end

  def generate_next_teacher_exercise_number
    ActiveRecord::Base.connection.select_value("SELECT nextval('teacher_exercise_number')")
  end
end
