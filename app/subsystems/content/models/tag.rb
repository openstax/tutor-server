class Content::Models::Tag < Tutor::SubSystems::BaseModel

  belongs_to :ecosystem, inverse_of: :tags

  has_many :page_tags, dependent: :destroy, inverse_of: :tag
  has_many :pages, through: :page_tags

  has_many :exercise_tags, dependent: :destroy, inverse_of: :tag
  has_many :exercises, through: :exercise_tags

  has_many :lo_teks_tags, foreign_key: :lo_id, dependent: :destroy
  has_many :teks_tags, through: :lo_teks_tags, class_name: 'Tag', source: :teks

  has_many :same_value_tags, class_name: 'Tag', primary_key: 'value', foreign_key: 'value'

  # List the different types of tags
  enum tag_type: [ :generic, :lo, :aplo, :teks, :dok, :blooms, :length ]

  validates :value, presence: true
  validates :tag_type, presence: true

  before_save :update_tag_type_data_and_visible

  OBJECTIVE_TAG_TYPES = ['lo', 'aplo'].collect{ |type| tag_types[type] }

  TAG_TYPE_REGEX = {
    dok: /^dok(\d+)$/,
    blooms: /^blooms-(\d+)$/,
    length: /^time-(.+)$/,
    teks: /^ost-tag-teks-.*-(.+)$/,
    lo: /-lo\d+$/
  }

  VISIBLE_TAG_TYPES = [:lo, :aplo, :teks, :dok, :blooms, :length]

  def book_location
    matches = /-ch(\d+)-s(\d+)-lo\d+$/.match(value)
    matches.nil? ? [] : [matches[1].to_i, matches[2].to_i]
  end

  def name
    read_attribute(:name) || (
      convert(/dok(\d+)/, "DOK: $1") ||
      convert(/blooms\-(\d+)/, "Blooms: $1") ||
      convert(/time-short/, "Length: S") ||
      convert(/time-med/, "Length: M") ||
      convert(/time-long/, "Length: L")
    )
  end

  protected

  def convert(regex, template)
    match_data = value.match(regex)
    return nil if match_data.nil?

    (1..match_data.length-1).each do |match_index|
      template.gsub!("$#{match_index}", match_data[match_index])
    end

    template
  end

  def update_tag_type_data_and_visible
    self.tag_type = get_tag_type if tag_type.nil? || tag_type == 'generic'
    self.data = get_data if data.nil?
    self.visible = VISIBLE_TAG_TYPES.include?(tag_type.to_sym) if visible.nil?
    # need to return true here because if self.visible evaluates to false, the
    # record does not get saved
    true
  end

  def get_tag_type
    TAG_TYPE_REGEX.each do |type, regex|
      if value.match(regex)
        return type
      end
    end
    return :generic
  end

  def get_data
    m = value.match(TAG_TYPE_REGEX[tag_type.to_sym] || //)
    return m && m[1]
  end

end
