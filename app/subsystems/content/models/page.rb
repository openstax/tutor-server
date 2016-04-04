class Content::Models::Page < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Page

  acts_as_resource

  serialize :book_location, Array

  belongs_to :reading_dynamic_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :reading_try_another_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :homework_core_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :homework_dynamic_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :practice_widget_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :all_exercises_pool, class_name: 'Content::Models::Pool', dependent: :destroy

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages
  has_one :book, through: :chapter
  has_one :ecosystem, through: :book

  has_many :exercises, dependent: :destroy, inverse_of: :page

  has_many :page_tags, dependent: :destroy, autosave: true, inverse_of: :page
  has_many :tags, through: :page_tags

  validates :book_location, presence: true
  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  delegate :is_intro?, to: :parser

  def cnx_id
    "#{uuid}@#{version}"
  end

  def los
    tags.to_a.select(&:lo?)
  end

  def aplos
    tags.to_a.select(&:aplo?)
  end

  def ccs
    tags.to_a.select(&:cc?)
  end

  def fragments
    return @fragments unless @fragments.nil?

    @fragments = fragment_splitter.split_into_fragments(parser.converted_root)
  end

  def snap_labs
    parser.snap_lab_nodes.map do |snap_lab_node|
      {
        id: "#{self.id}:#{snap_lab_node.attr('id')}",
        title: parser.snap_lab_title(snap_lab_node),
        fragments: fragment_splitter.split_into_fragments(snap_lab_node)
      }
    end
  end

  protected

  def parser
    @parser ||= OpenStax::Cnx::V1::Page.new(title: title, content: content)
  end

  def fragment_splitter
    @fragment_splitter ||= OpenStax::Cnx::V1::FragmentSplitter.new(
      book.reading_processing_instructions
    )
  end

end
