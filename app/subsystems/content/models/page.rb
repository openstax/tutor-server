class Content::Models::Page < IndestructibleRecord
  wrapped_by ::Content::Strategies::Direct::Page

  acts_as_resource

  auto_uuid :tutor_uuid

  json_serialize :fragments, OpenStax::Cnx::V1::Fragment, array: true
  json_serialize :snap_labs, Hash, array: true
  json_serialize :book_location, Integer, array: true
  json_serialize :baked_book_location, Integer, array: true

  belongs_to :reading_dynamic_pool, class_name: 'Content::Models::Pool',
                                    dependent: :destroy,
                                    optional: true
  belongs_to :reading_context_pool, class_name: 'Content::Models::Pool',
                                    dependent: :destroy,
                                    optional: true
  belongs_to :homework_core_pool, class_name: 'Content::Models::Pool',
                                  dependent: :destroy,
                                  optional: true
  belongs_to :homework_dynamic_pool, class_name: 'Content::Models::Pool',
                                     dependent: :destroy,
                                     optional: true
  belongs_to :practice_widget_pool, class_name: 'Content::Models::Pool',
                                    dependent: :destroy,
                                    optional: true
  belongs_to :concept_coach_pool, class_name: 'Content::Models::Pool',
                                  dependent: :destroy,
                                  optional: true
  belongs_to :all_exercises_pool, class_name: 'Content::Models::Pool',
                                  dependent: :destroy,
                                  optional: true

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages
  has_one :book, through: :chapter
  has_one :ecosystem, through: :book

  has_many :exercises, dependent: :destroy, inverse_of: :page
  has_many :page_tags, dependent: :destroy, inverse_of: :page
  has_many :tags, through: :page_tags

  has_many :same_uuid_pages, class_name: 'Page', primary_key: 'uuid', foreign_key: 'uuid'

  has_many :task_steps, subsystem: :tasks, dependent: :destroy, inverse_of: :page

  has_many :notes, subsystem: :content, dependent: :destroy, inverse_of: :page

  validates :book_location, presence: true
  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  scope :book_location, ->(chapter, section) do
    where("content_pages.book_location = '[?,?]'", chapter.to_i, section.to_i)
  end

  delegate :is_intro?, to: :parser

  def tutor_title
    # Chapter intro pages get their titles from the chapter instead
    is_intro? ? chapter.title : title
  end

  def related_content
    {
      uuid: uuid,
      page_id: id,
      title: tutor_title,
      book_location: book_location,
      baked_book_location: baked_book_location
    }
  end

  def cnx_id
    "#{uuid}@#{version}"
  end

  def los
    tags.filter(&:lo?)
  end

  def aplos
    tags.filter(&:aplo?)
  end

  def cnxmods
    tags.filter(&:cnxmod?)
  end

  def cache_fragments_and_snap_labs
    return if id.nil? || fragment_splitter.nil?

    self.fragments = fragment_splitter.split_into_fragments(parser.converted_root).map(&:to_yaml)
    self.snap_labs = parser.snap_lab_nodes.map do |snap_lab_node|
      {
        id: snap_lab_node.attr('id'),
        title: parser.snap_lab_title(snap_lab_node),
        fragments: fragment_splitter.split_into_fragments(snap_lab_node, 'snap-lab').map(&:to_yaml)
      }
    end
  end

  def fragments
    @fragments ||= (super || []).map { |yaml| YAML.load(yaml) }
  end

  def fragments=(fragments)
    @fragments = nil
    super
  end

  def snap_labs
    @snap_labs ||= (super || []).map do |snap_lab|
      sl = snap_lab.symbolize_keys
      sl.merge fragments: sl[:fragments].map { |yaml| YAML.load(yaml) }
    end
  end

  def snap_labs=(snap_labs)
    @snap_labs = nil
    super
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

  def reference_view_url(book = chapter.book)
    raise('Unpersisted Page') if id.nil?

    "#{book.reference_view_url}/page/#{id}"
  end

  protected

  def parser_class
    OpenStax::Cnx::V1::Page
  end

  def parser
    @parser ||= parser_class.new(url: url, title: title, content: content)
  end

  def fragment_splitter
    return if chapter&.book.nil?

    @fragment_splitter ||= OpenStax::Cnx::V1::FragmentSplitter.new(
      chapter.book.reading_processing_instructions, reference_view_url
    )
  end
end
