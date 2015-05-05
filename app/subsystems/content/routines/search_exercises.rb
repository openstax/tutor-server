class Content::Routines::SearchExercises

  lev_routine express_output: :items

  uses_routine OSU::OrderRelation, as: :order,
               translations: { outputs: { type: :verbatim } }

  SORTABLE_FIELDS = {
    'url' => :url,
    'title' => :title,
    'created_at' => :created_at
  }

  protected

  def exec(options = {})

    relation = options[:relation] || Content::Models::Exercise.latest.preload(exercise_tags: :tag)
    urls = [options[:url]].flatten unless options[:url].nil?
    titles = [options[:title]].flatten unless options[:title].nil?
    tags = [options[:tag]].flatten unless options[:tag].nil?

    query_hash = {}
    query_hash[:url] = urls unless urls.nil?
    query_hash[:title] = titles unless titles.nil?

    relation = relation.where(query_hash)

    unless tags.nil?
      match_count = options[:match_count] || tags.size
      # Tag intersection
      # http://stackoverflow.com/a/2000642
      relation = relation.joins(exercise_tags: :tag)
                         .where(exercise_tags: {tag: {value: tags}})
                         .group(:id).having{
                           count(distinct(exercise_tags.tag.id)).gteq match_count
                         }
    end

    run(:order, options.merge(relation: relation, sortable_fields: SORTABLE_FIELDS))
  end
end
