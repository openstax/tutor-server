class CourseContent::AddEcosystemToCourses
  lev_routine

  uses_routine AddEcosystemToCourse, as: :add_ecosystem_to_course

  protected
  def exec(courses:, ecosystem:, remove_other_ecosystems: false,
           ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
           map_strategy_class: ::Content::Strategies::Generated::Map)
    courses = courses.collect { |c| Marshal.load(c) } if courses.first.is_a? String
    ecosystem = Marshal.load(ecosystem) if ecosystem.is_a? String
    outputs[:ecosystem_maps] = courses.collect do |course|
      run(:add_ecosystem_to_course, course: course, ecosystem: ecosystem,
          remove_other_ecosystems: remove_other_ecosystems,
          ecosystem_strategy_class: ecosystem_strategy_class,
          map_strategy_class: map_strategy_class).outputs.ecosystem_map
    end
  end
end
