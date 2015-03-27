class Content::SearchLocalExercises

  lev_routine

  uses_routine OSU::SearchAndOrganizeRelation,
               as: :search,
               translations: { outputs: { type: :verbatim } }

  SORTABLE_FIELDS = {
    'url' => :url,
    'title' => :title,
    'created_at' => :created_at
  }

  protected

  def exec(params = {})
    # Convert hash to string input
    query = params.collect{|k,v| "#{k}:\"#{[v].flatten.join(',')}\""}.join(' ')

    items = run(:search, relation: Content::Models::Exercise,
                         sortable_fields: SORTABLE_FIELDS,
                         params: {q: query}) do |with|

      with.default_keyword :tag

      with.keyword :url do |urls|
        urls.each do |url|
          sanitized_urls = to_string_array(url)
          next @items = @items.none if sanitized_urls.empty?
          @items = @items.where(url: sanitized_urls)
        end
      end

      with.keyword :title do |titles|
        titles.each do |title|
          sanitized_titles = to_string_array(title)
          next @items = @items.none if sanitized_titles.empty?
          @items = @items.where(title: sanitized_titles)
        end
      end

      with.keyword :tag do |tags|
        tags.each do |tag|
          sanitized_tags = to_string_array(tag).collect{|t| t.downcase}
          next @items = @items.none if sanitized_tags.empty?
          @items = @items.joins(exercise_tags: :tag)
                         .where(exercise_tags: {tag: {name: sanitized_tags}})
        end
      end
    end.outputs.items

    # Output OpenStax::Exercises::V1::Exercise objects
    outputs[:items] = items.collect do |i|
      OpenStax::Exercises::V1::Exercise.new(i.content)
    end
  end
end
