class Content::Models::Tag < IndestructibleRecord
  belongs_to :ecosystem, inverse_of: :tags

  has_many :page_tags, dependent: :destroy, inverse_of: :tag
  has_many :pages, through: :page_tags

  has_many :exercise_tags, dependent: :destroy, inverse_of: :tag
  has_many :exercises, through: :exercise_tags

  has_many :lo_teks_tags, foreign_key: :lo_id, dependent: :destroy
  has_many :teks_tags, through: :lo_teks_tags, class_name: 'Tag', source: :teks

  has_many :same_value_tags, class_name: 'Tag', primary_key: 'value', foreign_key: 'value'

  # List the different types of tags
  enum tag_type: [ :generic, :lo, :aplo, :teks, :dok, :blooms, :time,
                   :cnxmod, :id, :requires_context, :cnxfeature ]

  validates :value, presence: true
  validates :tag_type, presence: true

  before_save :update_tag_type_data_and_visible

  IMPORT_TAG_TYPES  = Set[ :lo, :aplo, :cnxmod ]
  MAPPING_TAG_TYPE = :lo
  VISIBLE_TAG_TYPES = Set[ :lo, :aplo, :teks, :dok, :blooms, :time ]

  def book_location
    Tagger.get_book_location(value)
  end

  def name
    read_attribute(:name) || Tagger.get_name(tag_type, data)
  end

  def import?
    IMPORT_TAG_TYPES.include?(tag_type.to_sym)
  end

  def mapping?
    MAPPING_TAG_TYPE == tag_type.to_sym
  end

  protected

  def update_tag_type_data_and_visible
    self.tag_type = Tagger.get_type(value) if tag_type.nil? || generic?
    self.data = Tagger.get_data(tag_type, value) if data.nil?
    self.visible = VISIBLE_TAG_TYPES.include?(tag_type.to_sym) if visible.nil?
  end
end
