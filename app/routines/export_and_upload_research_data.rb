  class ExportAndUploadResearchData

  owncloud_secrets = Rails.application.secrets['owncloud']
  RESEARCH_FOLDER = owncloud_secrets['research_folder']
  WEBDAV_BASE_URL = "#{owncloud_secrets['base_url']}/remote.php/webdav/#{RESEARCH_FOLDER}"

  lev_routine express_output: :filename

  def exec(filename: nil, task_types: [], from: nil, to: nil)
    fatal_error(code: :tasks_types_missing, message: "You must specify the types of Tasks") \
      if task_types.blank?
    outputs[:filename] = FilenameSanitizer.sanitize(filename) ||
                         "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
    date_range = (Chronic.parse(from))..(Chronic.parse(to)) unless to.blank? || from.blank?
    create_export_file(task_types, date_range)
    upload_export_file
    remove_export_file
  end

  protected

  def filepath
    File.join 'tmp', 'exports', outputs[:filename]
  end

  def create_export_file(task_types, date_range)
    CSV.open(filepath, 'w') do |file|
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

      steps = steps.where(task: { created_at: date_range }) if date_range
      steps = steps.where(task: { task_type: task_types })

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

          role_id = step.task.taskings.first.entity_role_id
          r_info = role_info[role_id]
          next if r_info.nil?

          tasked = step.tasked
          type = step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1)
          course_id = r_info[:course_id]
          url = tasked.respond_to?(:url) ? tasked.url : nil

          row = [
            r_info[:research_identifier],
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
                # escape so Excel doesn't see as formula
                tasked.free_response.try(:gsub, /\A=/,"'="),
                tasked.tags.join(',')
              ]
            when 'Reading'
              [
                url + ".json", nil, nil, nil, nil
              ]
            else
              5.times.map{nil}
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
    @role_info ||= {}.tap do |role_info|
      CourseMembership::Models::Student
        .joins(:course, :role)
        .where(course: { is_preview: false, is_test: false })
        .with_deleted
        .pluck(:entity_role_id, :course_profile_course_id, :research_identifier)
        .each do |entity_role_id, course_profile_course_id, research_identifier|
          role_info[entity_role_id] = {
            research_identifier: research_identifier,
            course_id: course_profile_course_id
          }
        end
    end
  end

  def is_cc?(course_id)
    @is_cc_map ||= CourseProfile::Models::Course.pluck(:id, :is_concept_coach).to_h

    @is_cc_map[course_id].to_s.upcase
  end

  def format_time(time)
    return time if time.blank?
    time.utc.iso8601
  end

  def upload_export_file
    own_cloud_secrets = Rails.application.secrets['owncloud']
    auth = { username: own_cloud_secrets['username'], password: own_cloud_secrets['password'] }

    File.open(filepath, 'r') do |file|
      HTTParty.put(webdav_url, basic_auth: auth, body_stream: file,
                               headers: { 'Transfer-Encoding' => 'chunked' }).success?
    end
  end

  def remove_export_file
    File.delete(filepath) if File.exist?(filepath)
  end

  def webdav_url
    Addressable::URI.escape "#{WEBDAV_BASE_URL}/#{outputs[:filename]}"
  end

end
