class SearchCourses
  lev_routine express_output: :items

  protected

  def exec(query:)
    if query.nil?
      courses = Entity::Course.joins(:profile)
    else
      q = "%#{query}%"
      courses = Entity::Course.joins{
        [profile.school.outer,
         profile.offering.outer,
         teachers.outer.role.outer.profile.outer.account.outer]
      }.where{
        (profile.name.like q) | \
        (profile.school.name.like q) | \
        (profile.offering.salesforce_book_name.like q) | \
        (profile.offering.description.like q) | \
        (teachers.role.profile.account.username.like q) | \
        (teachers.role.profile.account.first_name.like q) | \
        (teachers.role.profile.account.last_name.like q) | \
        (teachers.role.profile.account.full_name.like q)
      }
    end

    outputs.items = courses.order{ profile.name }
  end

end
