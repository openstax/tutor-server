class Content::Models::Page < Tutor::SubSystems::BaseModel

  wrapped_by ::Ecosystem::Strategies::Direct::Page

  acts_as_resource

  serialize :book_location, Array

  has_many :pools, dependent: :destroy, inverse_of: :page

  has_one :reading_dynamic_pool, -> {reading_dynamic}, class_name: 'Content::Models::Pool'
  has_one :reading_try_another_pool, -> {reading_try_another}, class_name: 'Content::Models::Pool'
  has_one :homework_core_pool, -> {homework_core}, class_name: 'Content::Models::Pool'
  has_one :homework_dynamic_pool, -> {homework_dynamic}, class_name: 'Content::Models::Pool'
  has_one :practice_widget_pool, -> {practice_widget}, class_name: 'Content::Models::Pool'

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages

  has_many :exercises, dependent: :destroy, inverse_of: :page

  has_many :page_tags, dependent: :destroy, autosave: true, inverse_of: :page
  has_many :tags, through: :page_tags

  validates :title, presence: true
  validates :book_location, presence: true

  delegate :fragments, :is_intro?, to: :parser

  def cnx_id
    "#{uuid}@#{version}"
  end

  def los
    tags.to_a.select(&:lo?)
  end

  def aplos
    tags.to_a.select(&:aplo?)
  end

  protected

  def parser
    OpenStax::Cnx::V1::Page.new(title: title, content: content)
  end

end
