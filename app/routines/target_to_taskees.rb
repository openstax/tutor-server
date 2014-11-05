class TargetToTaskees

  lev_routine

  protected

  def split_into_groups(taskees, group_size)
    # Split into groups of equal size
    result = []
    taskees.shuffle.each_slice(group_size) do |s|
      result << s
    end
    remainder = taskees.count % group_size

    # Redistribute last group if too few members
    if remainder > 0 && remainder < [group_size - 1, 2].max && \
                        remainder < result.count
      remainder_group = result.pop
      remainder_group.each_with_index do |taskee, i|
        result[i] << taskee
      end
    end

    result
  end

  def exec(target, options={})
    group_size = options[:group_size] || 1
    inc = options[:include] || [:students]

    taskees = case target
    when Section, Klass, Course, School
      inc.collect{ |inc| target.send(:inc) }.flatten
    when Student, Educator, CourseManager, SchoolManager, Administrator
      inc.include?(target.class.name.tableize) ? [target] : []
    else
      []
    end

    outputs[:taskee_groups] = split_into_groups(taskees, group_size)
  end

end
