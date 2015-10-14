class Content::Models::Tag < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Tag

  belongs_to :ecosystem, inverse_of: :tags

  has_many :page_tags, dependent: :destroy, inverse_of: :tag
  has_many :pages, through: :page_tags

  has_many :exercise_tags, dependent: :destroy, inverse_of: :tag
  has_many :exercises, through: :exercise_tags

  has_many :lo_teks_tags, foreign_key: :lo_id, dependent: :destroy
  has_many :teks_tags, through: :lo_teks_tags, class_name: 'Tag', source: :teks

  has_many :same_value_tags, class_name: 'Tag', primary_key: 'value', foreign_key: 'value'

  # List the different types of tags
  enum tag_type: [ :generic, :lo, :aplo, :teks, :dok, :blooms, :length, :cc ]

  validates :value, presence: true
  validates :tag_type, presence: true

  before_save :update_tag_data_and_visible

  MAPPING_TAG_TYPES = [:lo, :aplo, :cc].collect{ |type| tag_types[type] }
  VISIBLE_TAG_TYPES = [:lo, :aplo, :teks, :dok, :blooms, :length]

  def book_location
    matches = /[\w-]+-ch([\d-]{2})-s([\d-]{2})/.match(value)
    matches.nil? ? [] : [matches[1].to_i, matches[2].to_i]
  end

  protected

  def update_tag_data_and_visible
    self.data = get_data if data.nil?
    self.visible = VISIBLE_TAG_TYPES.include?(tag_type.to_sym) if visible.nil?
    # need to return true here because if self.visible evaluates to false, the
    # record does not get saved
    true
  end

  def get_data
    m = value.match(TAG_TYPE_REGEX[tag_type.to_sym] || //)
    return m && m[1]
  end

end
