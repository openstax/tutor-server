class Content::Models::Page < Tutor::SubSystems::BaseModel
  acts_as_resource

  serialize :chapter_section, Array

  sortable_belongs_to :book_part, on: :number, inverse_of: :pages

  has_many :page_tags, dependent: :destroy

  validates :title, presence: true

  delegate :fragments, :is_intro?, to: :parser

  protected

  def parser
    OpenStax::Cnx::V1::Page.new(title: title, content: content)
  end
end
