module Manager::StatsActions
  def self.included(base)
    base.class_attribute :course_url_proc
  end

  def courses
    @courses = Entity::Course.joins(:profile).preload(
      [:profile, :teachers, {periods: :active_enrollments}]
    ).order{ profile.name }.to_a
    @course_url_proc = course_url_proc

    render 'manager/stats/courses'
  end
end
