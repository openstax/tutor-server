class Content::Models::Tag < Tutor::SubSystems::BaseModel
  has_many :page_tags, dependent: :destroy
  has_many :exercise_tags, dependent: :destroy
  has_many :lo_teks_tags, foreign_key: :lo_id, dependent: :destroy
  has_many :teks_tags, through: :lo_teks_tags, class_name: 'Tag', source: :teks

  # List the different types of tags
  enum tag_type: [ :generic, :teks, :lo ]

  validates :value, presence: true
  validates :tag_type, presence: true

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


end
