class UpdateLtiScores
  lev_routine transaction: :no_transaction, use_jobba: true

  def exec(course:)
    raise ArgumentError, 'Course cannot be nil' if course.nil?

    @errors = []

    if course.environment.current?
      students_performance = Tasks::GetPerformanceReport[
        course: course, is_teacher: true
      ].flat_map { |period| period[:students] }.reject(&:is_dropped)
      data_by_task_plan_id = nil

      course.lti_contexts.each do |context|
        context.resource_links.select(&:can_update_scores?).each do |resource_link|
          lineitems = nil

          if resource_link.can_create_lineitems?
            begin
              # Get existing lineitems
              lineitems = resource_link.lineitems
              lineitems_by_task_plan_uuid = lineitems.index_by(&:resourceId)

              data_by_task_plan_id ||= students_performance.flat_map(&:data).group_by do |datum|
                datum.task.tasks_task_plan_id
              end
              data_by_task_plan_id.each do |task_plan_id, data|
                tasks = data.map(&:task)

                # Find or create lineitem for each task_plan
                task_plan_id_string = task_plan_id.to_s
                lineitem = lineitems_by_task_plan_uuid[task_plan_id_string]
                lineitem = Lti::Lineitem.new(resourceId: task_plan_id_string) if lineitem.nil?

                lineitem.startDateTime = tasks.map(&:opens_at).min
                lineitem.endDateTime = tasks.map(&:closes_at).max

                lineitem.scoreMaximum = data.map(&:available_points).max
                lineitem.label = data.first.task.task_plan.title
                lineitem.tag = 'grade'
                begin
                  lineitem.save!

                  # Upload scores for each task
                  tasks.each do |task|
                    begin
                      # ...
                    rescue StandardError => exception
                      error!(
                        exception: exception,
                        message: exception.message,
                        course: course.id,
                        resource_link: resource_link.inspect,
                        lineitem: lineitem.inspect,
                        task: task
                      )
                    end
                  end
                rescue StandardError => exception
                  error!(
                    exception: exception,
                    message: exception.message,
                    course: course.id,
                    resource_link: resource_link.inspect,
                    lineitem: lineitem.inspect
                  )
                end
              end
            rescue StandardError => exception
              error!(
                exception: exception,
                message: exception.message,
                course: course.id,
                resource_link: resource_link.inspect
              )
            end
          end

          begin
            lineitems ||= [ resource_link.lineitem ]
            lineitem = lineitems.find { |lineitem| lineitem.resource_id.blank? }
            next if lineitem.nil?

            # Upload average scores for each student
            # ...
          rescue StandardError => exception
            error!(
              exception: exception,
              message: exception.message,
              course: course.id,
              resource_link: resource_link.inspect
            )
          end
        end
      end
    else
      error! message: 'This course was created in a different environment', course: course.id
    end

    return if @errors.empty?

    # Send errors to sentry
    @errors.each do |error|
      exception = error[:exception]

      if exception.nil?
        Raven.capture_message error[:message], extra: error.except(:message)
      else
        Raven.capture_exception exception, extra: error.except(:exception)
      end
    end
  end

  protected

  def error!(error)
    @errors.push error
    status.add_error error
    Rails.logger.error do
      "[#{self.class.name}] #{'(' + status.id + ')' if status.present?
        } #{error.except(:exception).inspect}"
    end
  end
end
