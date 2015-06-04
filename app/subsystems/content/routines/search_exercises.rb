class Content::Routines::SearchExercises

  lev_routine express_output: :items

  uses_routine OSU::OrderRelation, as: :order,
               translations: { outputs: { type: :verbatim } }

  SORTABLE_FIELDS = {
    'url' => :url,
    'title' => :title,
    'number' => :number,
    'version' => :version,
    'created_at' => :created_at
  }

  protected

  def exec(options = {})

    relation = options[:relation] || Content::Models::Exercise.preload(exercise_tags: :tag)
    urls = [options[:url]].flatten unless options[:url].nil?
    titles = [options[:title]].flatten unless options[:title].nil?
    tags = [options[:tag]].flatten unless options[:tag].nil?
    numbers = [options[:number]].flatten unless options[:number].nil?
    versions = [options[:version]].flatten unless options[:version].nil?
    uids = [options[:uid]].flatten unless options[:uid].nil?

    query_hash = {}
    query_hash[:url] = urls unless urls.nil?
    query_hash[:title] = titles unless titles.nil?
    query_hash[:number] = numbers unless numbers.nil?
    query_hash[:version] = versions unless versions.nil?

    # If no version is specified, return only the latest
    relation = relation.latest if urls.nil? && versions.nil? && uids.nil?

    relation = relation.where(query_hash)

    unless uids.nil?
      relation = relation.where do
        cumulative_query = nil
        uids.each do |uid|
          n, v = uid.split('@')
          query = ((number == n) & (version == v))
          cumulative_query = cumulative_query.nil? ? query : (cumulative_query | query)
        end

        cumulative_query
      end
    end

    unless tags.nil?
      match_count = options[:match_count] || tags.size
      # Tag intersection
      # http://stackoverflow.com/a/2000642
      relation = relation.joins(exercise_tags: :tag)
                         .where(exercise_tags: {tag: {value: tags}})
                         .group(:id).having {
                           count(distinct(exercise_tags.tag.id)).gteq match_count
                         }
    end

    run(:order, options.merge(relation: relation, sortable_fields: SORTABLE_FIELDS))
  end
end
