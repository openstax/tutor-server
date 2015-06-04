class Content::Models::Tag < Tutor::SubSystems::BaseModel
  has_many :page_tags, dependent: :destroy
  has_many :exercise_tags, dependent: :destroy
  has_many :lo_teks_tags, foreign_key: :lo_id, dependent: :destroy
  has_many :teks_tags, through: :lo_teks_tags, class_name: 'Tag', source: :teks

  # List the different types of tags
  enum tag_type: [ :generic, :teks, :lo, :dok, :blooms, :length ]

  validates :value, presence: true
  validates :tag_type, presence: true

  before_save :update_tag_type

  TAG_TYPE_REGEX = {
    dok: /^dok/,
    blooms: /^blooms-/,
    length: /^time-/,
    teks: /^ost-tag-teks-/,
    lo: /-lo\d+$/
  }

  def chapter_section
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

  def update_tag_type
    self.tag_type = get_tag_type if tag_type.nil? || tag_type == 'generic'
  end

  def get_tag_type
    TAG_TYPE_REGEX.each do |type, regex|
      if value.match(regex)
        return type
      end
    end
    return :generic
  end

end
