class SearchCourses
  lev_routine outputs: { items: :_self }

  protected

  def exec(query:)
    if query.nil?
      courses = Entity::Course.joins(:profile)
    else
      q = "%#{query}%"
      courses = Entity::Course.joins{
        [profile.school.outer, teachers.outer.role.outer.profile.outer.account.outer]
      }.where{
        (profile.name.like q) | \
        (profile.school.name.like q) | \
        (teachers.role.profile.account.username.like q) | \
        (teachers.role.profile.account.first_name.like q) | \
        (teachers.role.profile.account.last_name.like q) | \
        (teachers.role.profile.account.full_name.like q)
      }
    end

    set(items: courses.order{ profile.name })
  end

end
