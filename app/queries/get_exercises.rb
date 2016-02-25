class GetExercises

  # Returns Content::Exercises filtered "by":
  #   :ecosystem or :course
  #   :page_ids (defaults to all)
  #   :pool_types (defaults to all)
  #
  # :with is an array that instructs to return extra information with the exercises, can include:
  #   :course_exercise_options (if :course provided)
  # :with always effectively includes :pool_type by default

  def self.[](by:, with: nil)
    new.run(by: by, with: with)
  end

  def run(by:, with:)
    @by = by
    @with = [with].flatten.compact

    pools.each do |pool|
      pool.exercises(preload_tags: true).each do |exercise|
        record_exercise(exercise)
        record_pool_type(exercise, pool.type)
        record_course_exercise_options(exercise)
      end
    end

    result
  end

  def ecosystem
    raise "Either :ecosystem or :course must be provided" unless @by[:ecosystem] || @by[:course]
    @ecosystem ||= @by[:ecosystem] || GetCourseEcosystems[course: @by[:course]].first
  end

  def pages
    @pages ||= @by[:page_ids] ? ecosystem.pages_by_ids(@by[:page_ids]) : ecosystem.pages
  end

  def pools
    if !@pools
      # Default to all pool types
      pool_types = [by[:pool_types]].flatten.compact.uniq
      pool_types = Content::Pool.pool_types if pool_types.empty?

      @pools = pool_types.collect{|pt| ecosystem.send("#{pt}_pools".to_sym, pages: pages)}
    end
    @pools
  end

  def record_exercise(exercise)
    @result[exercise.uid] ||= exercise
  end

  def record_pool_type(exercise, pool_type)
    @result[exercise.uid]['pool_types'] ||= []
    @result[exercise.uid]['pool_types'] << pool_type
  end

  def record_course_exercise_options(exercise)
    return unless @with.include?(:course_exercise_options)

    raise "To return course exercise options, a :course must have been provided" unless @by[:course]

    @course_exercise_options ||=
      CourseContent::Models::ExerciseOptions.where(entity_course_id: @by[:course].id).all.each_with_object do |eo, hash|
        hash[eo.exercise_uid] = eo
      end
    end

    @result[exercise.uid]['course_exercise_options'] = @course_exercise_options[exercise.uid]
  end

  def result
    @result ||= {}
  end

end
