class Content::Models::Page < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Page

  acts_as_resource

  auto_uuid :tutor_uuid

  json_serialize :fragments, OpenStax::Cnx::V1::Fragment, array: true
  json_serialize :snap_labs, Hash, array: true
  json_serialize :book_location, Integer, array: true

  belongs_to :reading_dynamic_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :reading_context_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :homework_core_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :homework_dynamic_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :practice_widget_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :concept_coach_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :all_exercises_pool, class_name: 'Content::Models::Pool', dependent: :destroy

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages
  has_one :book, through: :chapter
  has_one :ecosystem, through: :book

  has_many :exercises, dependent: :destroy, inverse_of: :page

  has_many :page_tags, dependent: :destroy, inverse_of: :page
  has_many :tags, through: :page_tags

  has_many :same_uuid_pages, class_name: 'Page', primary_key: 'uuid', foreign_key: 'uuid'

  validates :book_location, presence: true
  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  before_validation :cache_fragments_and_snap_labs

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

  def cnxmods
    tags.to_a.select(&:cnxmod?)
  end

  def fragments
    return @fragments unless @fragments.nil?
    return [] unless cache_fragments_and_snap_labs

    frags = super
    @fragments = frags.nil? ? nil : frags.map{ |yaml| YAML.load(yaml) }
  end

  def snap_labs
    return @snap_labs unless @snap_labs.nil?
    return [] unless cache_fragments_and_snap_labs

    sls = super
    @snap_labs = sls.nil? ? nil : sls.map do |snap_lab|
      sl = snap_lab.symbolize_keys
      sl.merge(fragments: sl[:fragments].map{ |yaml| YAML.load(yaml) })
    end
  end

  def snap_labs_with_page_id
    snap_labs.map{ |snap_lab| snap_lab.merge(page_id: id) }
  end

  def context_for_feature_ids(feature_ids)
    @context_for_feature_ids ||= {}
    return @context_for_feature_ids[feature_ids] if @context_for_feature_ids.has_key?(feature_ids)

    feature_node = nil
    fragments.each do |fragment|
      next unless fragment.respond_to?(:to_html)

      fragment_node = Nokogiri::HTML.fragment(fragment.to_html)
      feature_node = parser_class.feature_node(fragment_node, feature_ids)

      break unless feature_node.nil?
    end

    @context_for_feature_ids[feature_ids] = feature_node.try(:to_html)
  end

  protected

  def parser_class
    OpenStax::Cnx::V1::Page
  end

  def parser
    @parser ||= parser_class.new(title: title, content: content)
  end

  def fragment_splitter
    return if chapter.try(:book).nil?

    @fragment_splitter ||= OpenStax::Cnx::V1::FragmentSplitter.new(
      chapter.book.reading_processing_instructions
    )
  end

  def cache_fragments_and_snap_labs
    return true if read_attribute(:fragments).present?
    return false if fragment_splitter.nil?

    self.snap_labs = parser.snap_lab_nodes.map do |snap_lab_node|
      {
        id: snap_lab_node.attr('id'),
        title: parser.snap_lab_title(snap_lab_node),
        fragments: fragment_splitter.split_into_fragments(snap_lab_node, 'snap-lab').map(&:to_yaml)
      }
    end
    self.fragments = fragment_splitter.split_into_fragments(parser.converted_root).map(&:to_yaml)

    true
  end

end
