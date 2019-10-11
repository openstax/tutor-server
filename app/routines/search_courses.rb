class SearchCourses

  lev_routine express_output: :items

  uses_routine OSU::SearchAndOrganizeRelation,
               as: :search,
               translations: { outputs: { type: :verbatim } }

  SORTABLE_FIELDS = {
    'id' => :id,
    'name' => :name,
    'school' => SchoolDistrict::Models::School.arel_table[:name],
    'offering' => Catalog::Models::Offering.arel_table[:number],
    'created_at' => :created_at,
    'updated_at' => :updated_at
  }

  protected

  def exec(params = {}, options = {})
    params[:order_by] ||= :name
    relation = CourseProfile::Models::Course.without_deleted.left_outer_joins(
      :school,
      :offering,
      :periods,
      teachers: { role: { profile: :account } },
      course_ecosystems: :ecosystem
    ).distinct

    run(:search, relation: relation, sortable_fields: SORTABLE_FIELDS, params: params) do |with|

      with.default_keyword :any

      co = CourseProfile::Models::Course.arel_table
      sc = SchoolDistrict::Models::School.arel_table
      of = Catalog::Models::Offering.arel_table
      ac = OpenStax::Accounts::Account.arel_table
      pe = CourseMembership::Models::Period.arel_table
      ec = Content::Models::Ecosystem.arel_table

      with.keyword :any do |queries|
        queries.each do |query|
          sanitized_ids = to_number_array(query)
          sanitized_queries = to_string_array(query, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_ids.empty? && sanitized_queries.empty?

          @items = @items.where(
            co[:id].in(sanitized_ids).or(
              co[:name].matches_any(sanitized_queries)
            ).or(
              sc[:name].matches_any(sanitized_queries)
            ).or(
              of[:title].matches_any(sanitized_queries)
            ).or(
              of[:description].matches_any(sanitized_queries)
            ).or(
              of[:salesforce_book_name].matches_any(sanitized_queries)
            ).or(
              of[:appearance_code].matches_any(sanitized_queries)
            ).or(
              ac[:username].matches_any(sanitized_queries)
            ).or(
              ac[:first_name].matches_any(sanitized_queries)
            ).or(
              ac[:last_name].matches_any(sanitized_queries)
            ).or(
              ac[:full_name].matches_any(sanitized_queries)
            ).or(
              pe[:enrollment_code].matches_any(sanitized_queries)
            ).or(
              ec[:title].matches_any(sanitized_queries)
            )
          )
        end
      end

      with.keyword :id do |ids|
        ids.each do |id|
          sanitized_ids = to_number_array(id)
          next @items = @items.none if sanitized_ids.empty?
          @items = @items.where(id: sanitized_ids)
        end
      end

      with.keyword :enrollment do |ids|
        ids.each do |id|
          sanitized_ids = to_string_array(id, append_wildcard: false, prepend_wildcard: false)
          next @items = @items.none if sanitized_ids.empty?

          @items = @items.where(pe[:enrollment_code].matches_any(sanitized_ids))
        end
      end

      with.keyword :name do |names|
        names.each do |name|
          sanitized_names = to_string_array(name, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_names.empty?

          @items = @items.where(co[:name].matches_any(sanitized_names))
        end
      end

      with.keyword :school do |names|
        names.each do |name|
          sanitized_names = to_string_array(name, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_names.empty?

          @items = @items.joins(:school).where(sc[:name].matches_any(sanitized_names))
        end
      end

      with.keyword :offering do |queries|
        queries.each do |query|
          sanitized_queries = to_string_array(query, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.joins(:offering).where(
            of[:title].matches_any(sanitized_queries).or(
              of[:description].matches_any(sanitized_queries)
            ).or(
              of[:salesforce_book_name].matches_any(sanitized_queries)
            ).or(
              of[:appearance_code].matches_any(sanitized_queries)
            )
          )
        end
      end

      with.keyword :teacher do |names|
        names.each do |name|
          sanitized_names = to_string_array(name, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_names.empty?

          @items = @items.joins(teachers: { role: { profile: :account } }).where(
            ac[:username].matches_any(sanitized_names).or(
              ac[:first_name].matches_any(sanitized_names)
            ).or(
              ac[:last_name].matches_any(sanitized_names)
            ).or(
              ac[:full_name].matches_any(sanitized_names)
            )
          )
        end
      end

      with.keyword :ecosystem do |titles|
        titles.each do |title|
          sanitized_titles = to_string_array(title, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_titles.empty?

          @items = @items.joins(course_ecosystems: :ecosystem).where(
            ec[:title].matches_any(sanitized_titles)
          )
        end
      end

      with.keyword :offering_id do |queries|
        queries.each do |query|
          sanitized_queries = to_number_array(query)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where(catalog_offering_id: sanitized_queries)
        end
      end

      with.keyword :is_lms_enabled do |queries|
        queries.each do |query|
          sanitized_queries = to_boolean_array(query, allow_nil: true)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where(is_lms_enabled: sanitized_queries)
        end
      end

      with.keyword :is_lms_enabling_allowed do |queries|
        queries.each do |query|
          sanitized_queries = to_boolean_array(query, allow_nil: false)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where(is_lms_enabling_allowed: sanitized_queries)
        end
      end

      with.keyword :term do |terms|
        terms.each do |term|
          sanitized_term_values = to_string_array(term).map do |tt|
            CourseProfile::Models::Course.terms[tt.downcase]
          end
          next @items = @items.none if sanitized_term_values.empty?

          @items = @items.where(term: sanitized_term_values)
        end
      end

      with.keyword :year do |years|
        years.each do |year|
          sanitized_years = to_number_array(year)
          next @items = @items.none if sanitized_years.empty?

          @items = @items.where(year: sanitized_years)
        end
      end

      with.keyword :costs do |queries|
        queries.each do |query|
          sanitized_queries = to_boolean_array(query, allow_nil: false)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where(does_cost: sanitized_queries)
        end
      end

      with.keyword :is_preview, nil, "false" do |queries|
        queries.each do |query|
          sanitized_queries = to_boolean_array(query, allow_nil: false)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where(is_preview: sanitized_queries)
        end
      end
    end
  end
end

class OpenStax::Utilities::SearchRelation
  def to_boolean_array(input, allow_nil: false)
    array = to_string_array(input).map do |ii|
      ii.downcase!

      if ['true', 't'].include?(ii)
        true
      elsif ['false', 'f'].include?(ii)
        false
      else
        nil
      end
    end

    array.compact! if !allow_nil
    array
  end
end
