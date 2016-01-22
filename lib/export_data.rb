class ExportData

  def self.call(filepath=nil)
    filepath ||= "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.xlsx"
    export = new(filepath)
    export.build
    export.save
    filepath
  end

  def build
    create_summary_worksheet
    create_task_step_worksheet
  end

  def save
    @package.serialize(@filepath)
  end

  protected

  attr_reader :filepath, :package, :workbook, :bold, :date

  def initialize(filepath)
    @filepath = filepath
    @package = Axlsx::Package.new do |pp|
      pp.use_shared_strings = true # OS X Numbers interoperability
    end
    @workbook = @package.workbook

    workbook.styles do |s|
      @bold = s.add_style b: true
      @date = s.add_style(:format_code => "yyyy-mm-ddTHH:mm:ssZ")
    end
  end

  def create_summary_worksheet
    sheet = new_sheet(name: 'Info', freeze: false)

    sheet.add_row ["Title", "Tutor Data Export"], style: bold
    sheet.add_row ["Exported At", Time.now.utc], style: [nil, date]
    sheet.add_row ["Confidential data; distribute to authorized persons only"], style: bold
  end

  def create_task_step_worksheet
    sheet = new_sheet(name: "Data")

    sheet.add_row(
      [
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
      ],
      style: bold
    )

    steps = Tasks::Models::TaskStep.order(tasks_task_id: :asc, number: :asc)
                                   .joins{task.taskings}
                                   .includes(:tasked)

    total_count = steps.count
    current_count = 0

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

        columns = [
          [role_info[role_id].try(:[],:deidentifier), type: :string],
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
          [step.first_completed_at.try(:iso8601)],
          [step.last_completed_at.try(:iso8601)],
          [step.task.opens_at.try(:iso8601)],
          [step.task.due_at.try(:iso8601)],
          url
        ]

        columns.push(*(
          case type
          when 'Exercise'
            [
              url.gsub("org","org/api") + ".json",
              tasked.correct_answer_id,
              tasked.answer_id,
              tasked.is_correct?,
              tasked.free_response.try(:gsub, /\A=/,"'="), # escape so Excel doesn't see as formula
              tasked.tags
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

        add_row(sheet, columns)
      rescue StandardError => e
        print "\r"
        print "Skipped step #{step.id} for #{e.inspect} @ #{e.try(:backtrace).try(:first)}\n"
      end
    end
    puts "\n"
  end

  def add_row(sheet, optioned_values)
    values = []
    styles = []
    types = []

    optioned_values.each do |optioned_value|
      value, style, type =
        if optioned_value.is_a?(Array) && optioned_value.last.is_a?(Hash)
          [optioned_value[0], optioned_value[1][:style], optioned_value[1][:type]]
        else
          [optioned_value, nil]
        end

      value = value.join('; ') if value.is_a? Array

      values.push(value)
      styles.push(style)
      types.push(type)
    end

    sheet.add_row(values, style: styles, types: types)
  end

  def new_sheet(name:, freeze: true)
    workbook.add_worksheet(name: name) do |sheet|
      if freeze
        sheet.sheet_view.pane do |pane|
          pane.top_left_cell = "B2"
          pane.state = :frozen_split
          pane.y_split = 1
          pane.x_split = 1
          pane.active_pane = :bottom_right
        end
      end
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
        .all
        .each_with_object({}) do |profile, hsh|
          hsh[profile.entity_course_id] = profile.is_concept_coach
        end

    @is_cc_map[course_id]
  end

end
