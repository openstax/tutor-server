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
    relation = CourseProfile::Models::Course.joins do
      [school.outer,
       offering.outer,
       teachers.outer.role.outer.profile.outer.account.outer,
       ecosystems.outer]
    end.uniq

    run(:search, relation: relation, sortable_fields: SORTABLE_FIELDS, params: params) do |with|

      with.default_keyword :any

      with.keyword :any do |queries|
        queries.each do |query|
          sanitized_queries = to_string_array(query, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where do
            name.like_any(sanitized_queries) |
            school.name.like_any(sanitized_queries) |
            offering.title.like_any(sanitized_queries) |
            offering.description.like_any(sanitized_queries) |
            offering.salesforce_book_name.like_any(sanitized_queries) |
            offering.appearance_code.like_any(sanitized_queries) |
            teachers.role.profile.account.username.like_any(sanitized_queries) |
            teachers.role.profile.account.first_name.like_any(sanitized_queries) |
            teachers.role.profile.account.last_name.like_any(sanitized_queries) |
            teachers.role.profile.account.full_name.like_any(sanitized_queries) |
            ecosystems.title.like_any(sanitized_queries)
          end
        end
      end

      with.keyword :name do |names|
        names.each do |name|
          sanitized_names = to_string_array(name, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_names.empty?

          @items = @items.where{self.name.like_any sanitized_names}
        end
      end

      with.keyword :school do |names|
        names.each do |name|
          sanitized_names = to_string_array(name, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_names.empty?

          @items = @items.joins(:school).where{school.name.like_any sanitized_names}
        end
      end

      with.keyword :offering do |queries|
        queries.each do |query|
          sanitized_queries = to_string_array(query, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.joins(:offering).where do
            offering.title.like_any(sanitized_queries) |
            offering.description.like_any(sanitized_queries) |
            offering.salesforce_book_name.like_any(sanitized_queries) |
            offering.appearance_code.like_any(sanitized_queries)
          end
        end
      end

      with.keyword :teacher do |names|
        names.each do |name|
          sanitized_names = to_string_array(name, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_names.empty?

          @items = @items.joins(teachers: {role: {profile: :account}}).where do
            teachers.role.profile.account.username.like_any(sanitized_names) |
            teachers.role.profile.account.first_name.like_any(sanitized_names) |
            teachers.role.profile.account.last_name.like_any(sanitized_names) |
            teachers.role.profile.account.full_name.like_any(sanitized_names)
          end
        end
      end

      with.keyword :ecosystem do |titles|
        titles.each do |title|
          sanitized_titles = to_string_array(title, append_wildcard: true, prepend_wildcard: true)
          next @items = @items.none if sanitized_titles.empty?

          @items = @items.joins(:ecosystems).where { ecosystems.title.like_any(sanitized_titles) }
        end
      end

      with.keyword :offering_id do |queries|
        queries.each do |query|
          sanitized_queries = to_number_array(query)
          next @items = @items.none if sanitized_queries.empty?

          @items = @items.where(catalog_offering_id: sanitized_queries)
        end
      end
    end
  end
end
