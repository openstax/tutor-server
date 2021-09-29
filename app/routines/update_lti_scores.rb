class UpdateLtiScores
  lev_routine transaction: :no_transaction, use_jobba: true

  def exec(course:)
    raise ArgumentError, 'Course cannot be nil' if course.nil?

    @errors = []
    current_time = Time.current

    if course.environment.current?
      lti_contexts = course.lti_contexts.preload(:platform)
      lti_platform_ids = lti_contexts.map(&:lti_platform_id).uniq

      students_performance = Tasks::GetPerformanceReport[
        course: course, is_teacher: true
      ].flat_map { |period| period[:students] }.reject(&:is_dropped)
      user_profile_ids = students_performance.map(&:user)
      uid_by_platform_id_and_profile_id = Hash.new { |hash, key| hash[key] = {} }
      Lti::User.select(:lti_platform_id, :user_profile_id, :uid).where(
        lti_platform_id: lti_platform_ids, user_profile_id: user_profile_ids
      ).each do |user|
        uid_by_platform_id_and_profile_id[user.lti_platform_id][user.user_profile_id] = user.uid
      end
      data_by_task_plan = students_performance.flat_map do |student|
        student.data.map { |datum| datum.merge user: student.user }
      end.group_by { |datum| datum.task.task_plan }

      lti_contexts.each do |context|
        lti_platform_id = context.lti_platform_id
        uid_by_profile_id = uid_by_platform_id_and_profile_id[lti_platform_id]

        context.resource_links.select(&:can_update_scores?).each do |resource_link|
          lineitems = nil

          if resource_link.can_create_lineitems?
            begin
              # Get existing lineitems
              lineitems = resource_link.lineitems
              lineitems_by_task_plan_uuid = lineitems.index_by(&:resourceId)

              data_by_task_plan.each do |task_plan, data|
                # Find or create lineitem for each task_plan
                task_plan_id_string = task_plan.id.to_s
                lineitem = lineitems_by_task_plan_uuid[task_plan_id_string]
                lineitem = Lti::Lineitem.new(
                  resource_link: resource_link, resourceId: task_plan_id_string
                ) if lineitem.nil?

                tasks = data.map(&:task)
                lineitem.startDateTime = tasks.map(&:opens_at).min.iso8601
                lineitem.endDateTime = tasks.map(&:closes_at).max.iso8601

                lineitem.scoreMaximum = data.map(&:available_points).max
                lineitem.label = task_plan.title
                lineitem.tag = 'grade'
                begin
                  lineitem.save!

                  # Upload scores for each task
                  # The LTI spec says: `A tool MUST NOT send multiple score updates of the same
                  # (line item, user) with the same timestamp.` which maybe implies we need to
                  # keep track of (line item, user, timestamp) across different syncs.
                  # However, they also say `The platform MUST NOT update a result if the last
                  # timestamp on record is later than the incoming score update. It may just ignore
                  # the incoming score update, or log it if it maintains any kind of history or for
                  # traceability.` so sending the same timestamp in separate syncs should work fine.
                  # They also don't specify how to recover from missed updates, rollbacks etc
                  # when using partial updates...
                  data.each do |datum|
                    begin
                      uid = uid_by_profile_id[datum.user]
                      raise "User #{datum.user} not linked to LMS" if uid.nil?

                      task = datum.task

                      comment = "Late work penalty: -#{task.late_work_point_penalty}" if task.late?
                      activityProgress = if task.past_close?(current_time: current_time)
                        'Completed'
                      elsif task.completed?(use_cache: true)
                        'Submitted'
                      elsif task.started?(use_cache: true)
                        'Started'
                      else
                        'Initialized'
                      end
                      gradingProgress = if task.past_due?(current_time: current_time)
                        # If some LMS decides to reject score updates after FullyGraded,
                        # change this to Pending and send FullyGraded only after the close date
                        task.manual_grading_complete? ? 'FullyGraded' : 'PendingManual'
                      elsif task.started?(use_cache: true)
                        'Pending'
                      else
                        'NotReady'
                      end

                      score = Lti::Score.new(
                        lineitem: lineitem,
                        userId: uid,
                        scoreGiven: task.points,
                        scoreMaximum: task.available_points,
                        comment: comment,
                        timestamp: task.updated_at.iso8601(3),
                        activityProgress: activityProgress,
                        gradingProgress: gradingProgress
                      )

                      score.save!
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
            lineitem = lineitems.find { |lineitem| lineitem.resourceId.blank? }
            next if lineitem.nil?

            # TODO: Upload average scores for each student
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
