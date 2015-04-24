class Content::Routines::SearchPages

  lev_routine express_output: :items

  uses_routine OSU::OrderRelation, as: :order,
               translations: { outputs: { type: :verbatim } }

  SORTABLE_FIELDS = {
    'url' => :url,
    'title' => :title,
    'path' => :path,
    'created_at' => :created_at
  }

  protected

  def exec(options = {})

    relation = options[:relation] || Content::Models::Page.preload(page_tags: :tag)
    urls = [options[:url]].flatten unless options[:url].nil?
    titles = [options[:title]].flatten unless options[:title].nil?
    paths = [options[:path]].flatten unless options[:path].nil?
    tags = [options[:tag]].flatten unless options[:tag].nil?

    query_hash = {}
    query_hash[:url] = urls unless urls.nil?
    query_hash[:title] = titles unless titles.nil?
    query_hash[:path] = paths unless paths.nil?

    relation = relation.where(query_hash)

    unless tags.nil?
      match_count = options[:match_count] || tags.size
      # Tag intersection
      # http://stackoverflow.com/a/2000642
      relation = relation.joins(page_tags: :tag)
                         .where(page_tags: {tag: {name: tags}})
                         .group(:id)
                         .having{ count(distinct(page_tags.tag.id)).gteq match_count }
    end

    run(:order, options.merge(relation: relation, sortable_fields: SORTABLE_FIELDS))
  end
end
