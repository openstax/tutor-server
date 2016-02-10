class ExportAndUploadResearchData

  RESEARCH_FOLDER = Rails.application.secrets['owncloud']['research_folder']

  lev_routine

  def exec(filename = nil)
    outputs[:filename] = filename || "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
    create_export_file
    upload_export_file
    remove_export_file
  end

  protected

  def create_export_file
    CSV.open(outputs[:filename], 'w') do |file|
      file << [
        "Student",
        "Course ID",
        "CC?",
        "Period ID",
        "Plan ID",
        "Task ID",
        "Task Type",
        "Step ID",
        "Step Number",
        "Step Type",
        "Group",
        "First Completed At",
        "Last Completed At",
        "Opens At",
        "Due At",
        "URL",
        "API URL",
        "Correct Answer ID",
        "Answer ID",
        "Correct?",
        "Free Response",
        "Tags"
      ]

      steps = Tasks::Models::TaskStep.joins(task: :taskings)
                                     .preload([{task: :taskings}, :tasked])

      total_count = steps.count
      current_count = 0

      # find_each completely ignores any sort of limit or order
      steps.find_each do |step|
        begin
          if current_count % 20 == 0
            print "\r"
            print "#{current_count} / #{total_count}"
          end
          current_count += 1

          tasked = step.tasked
          type = step.tasked_type.match(/Tasked(.+)\z/).try(:[],1)
          role_id = step.task.taskings.first.entity_role_id
          course_id = role_info[role_id].try(:[],:course_id)
          url = tasked.respond_to?(:url) ? tasked.url : nil

          row = [
            role_info[role_id].try(:[],:deidentifier),
            course_id,
            is_cc?(course_id),
            step.task.taskings.first.course_membership_period_id,
            step.task.tasks_task_plan_id,
            step.tasks_task_id,
            step.task.task_type,
            step.id,
            step.number,
            type,
            step.group_name,
            format_time(step.first_completed_at),
            format_time(step.last_completed_at),
            format_time(step.task.opens_at),
            format_time(step.task.due_at),
            url
          ]

          row.push(*(
            case type
            when 'Exercise'
              [
                url.gsub("org","org/api") + ".json",
                tasked.correct_answer_id,
                tasked.answer_id,
                tasked.is_correct?,
                tasked.free_response.try(:gsub, /\A=/,"'="), # escape so Excel doesn't see as formula
                tasked.tags.join(',')
              ]
            when 'Reading'
              [
                url + ".json",
                nil, nil, nil, nil
              ]
            else
              5.times.collect{nil}
            end
          ))

          file << row
        rescue StandardError => e
          print "\r"
          print "Skipped step #{step.id} for #{e.inspect} @ #{e.try(:backtrace).try(:first)}\n"
        end
      end
      puts "\n"
    end
  end

  def role_info
    @role_info ||=
      CourseMembership::Models::Student
        .select([:entity_role_id, :deidentifier, :entity_course_id])
        .each_with_object({}) do |student, hsh|
          hsh[student.entity_role_id] = {
            deidentifier: student.deidentifier,
            course_id: student.entity_course_id
          }
        end
  end

  def is_cc?(course_id)
    @is_cc_map ||=
      CourseProfile::Models::Profile
        .select([:entity_course_id, :is_concept_coach])
        .each_with_object({}) do |profile, hsh|
          hsh[profile.entity_course_id] = profile.is_concept_coach
        end

    @is_cc_map[course_id]
  end

  def format_time(time)
    return time if time.blank?
    time.utc.iso8601
  end

  def upload_export_file
    own_cloud_secrets = Rails.application.secrets['owncloud']
    IO.popen("curl -K - -T #{outputs[:filename]} #{curl_url}", 'w') do |curl|
      curl.puts("user = #{own_cloud_secrets['username']}:#{own_cloud_secrets['password']}")
    end
    $?.exitstatus == 0
  end

  def remove_export_file
    File.delete(outputs[:filename]) if File.exist?(outputs[:filename])
  end

  def curl_url
    Addressable::URI.escape "https://share.cnx.org/remote.php/webdav/#{RESEARCH_FOLDER}/"
  end

end
