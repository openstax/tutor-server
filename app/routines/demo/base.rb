class Demo::Base
  protected

  def log(level = :info, &block)
    Rails.logger.tagged(self.class.name) { |logger| logger.public_send(level, &block) }
  end

  def log_status(name = nil)
    name_string = name.blank? ? '' : "#{name}: "
    if errors.empty?
      log(:info) { "#{name_string}Success" }
    else
      log(:error) { "#{name_string}Errors:\n#{errors.inspect}" }
    end
  end

  # Same as Random.srand but does not explode with a nil argument
  def srand(random_seed = nil)
    random_seed.nil? ? Random.srand : Random.srand(random_seed)
  end

  def find_course(course)
    if course[:id].blank?
      raise(ArgumentError, "Can't find a Course without a name or id") if course[:name].blank?

      CourseProfile::Models::Course.order(created_at: :desc).find_by name: course[:name]
    else
      CourseProfile::Models::Course.find_by id: course[:id]
    end
  end

  def find_course!(course)
    find_course(course) || raise(
      ActiveRecord::RecordNotFound,
      "Couldn't find a Course with #{course.slice(:id, :name).inspect}"
    )
  end

  def find_course_task_plans(course, task_plans)
    {}.tap do |task_plans_by_hash|
      task_plan_hashes_by_title = task_plans.reject { |task_plan| task_plan[:title].blank? }
                                            .index_by { |task_plan| task_plan[:title] }
      Tasks::Models::TaskPlan.where(owner: course, title: task_plan_hashes_by_title.keys)
                             .group_by(&:title)
                             .each do |title, task_plans|
        task_plans_by_hash[task_plan_hashes_by_title[title]] = task_plans.max_by(&:created_at)
      end

      task_plan_hashes_by_id = task_plans.reject { |task_plan| task_plan[:id].blank? }
                                         .index_by { |task_plan| task_plan[:id] }
      Tasks::Models::TaskPlan.where(owner: course, id: task_plan_hashes_by_id.keys)
                             .index_by(&:id)
                             .each do |id, task_plan|
        task_plans_by_hash[task_plan_hashes_by_id[id]] = task_plan
      end
    end
  end

  def find_course_task_plans!(course, task_plans)
    find_course_task_plans(course, task_plans).tap do |task_plans_by_hash|
      missing_task_plans = task_plans - task_plans_by_hash.keys
      next if missing_task_plans.empty?

      raise(
        ActiveRecord::RecordNotFound,
        "Could not find the following Task plan(s) in #{course.name}: #{
          missing_task_plans.map do |task_plan|
            task_plan.slice(:id, :title)
          end.map(&:inspect).join(', ')
        }"
      )
    end
  end
end
