class Content::Models::Page < Tutor::SubSystems::BaseModel
  acts_as_resource(url_not_unique: true)

  serialize :chapter_section, Array

  sortable_belongs_to :book_part, on: :number, inverse_of: :pages

  has_many :page_tags, dependent: :destroy
  has_many :tags, through: :page_tags

  validates :title, presence: true

  delegate :fragments, :is_intro?, to: :parser

  def cnx_id
    "#{uuid}@#{version}"
  end

  protected

  def parser
    OpenStax::Cnx::V1::Page.new(title: title, content: content)
  end
end
