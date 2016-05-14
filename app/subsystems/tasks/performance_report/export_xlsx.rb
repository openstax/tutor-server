module Tasks
  module PerformanceReport
    class ExportXlsx
      # include ActionView::Helpers::DateHelper

      def self.call(course_name:, report:, filename:)
        filename = "#{filename}.xlsx" unless filename.ends_with?(".xlsx")
        export = new(course_name: course_name, report: report, filepath: filename)
        export.create
        filename
      end

      # So can be called like other exporters
      def self.[](profile:, report:, filename:)
        call(course_name: profile.name, report: report, filename: filename)
      end

      def initialize(course_name:, report:, filepath:)
        @course_name = course_name
        @report = report
        @filepath = filepath
        @helper = XlsxHelper.new
      end

      def create
        @package = Axlsx::Package.new
        @helper.standard_package_settings(@package)

        setup_styles
        # exclude_non_due_tasks
        write_data_worksheets
        make_first_sheet_active
        save
      end

      private

      def exclude_non_due_tasks
        raise NotYetImplemented
      end

      def setup_styles
        @package.workbook.styles do |s|
          @title = s.add_style sz: 16
          @course_section = s.add_style sz: 14
          @bold = s.add_style b: true
          @italic = s.add_style i: true
          @pct = s.add_style num_fmt: Axlsx::NUM_FMT_PERCENT
          @italic_pct = s.add_style num_fmt: Axlsx::NUM_FMT_PERCENT, i: true
          @bold_L = s.add_style b: true, border: {edges: [:left], :color => '000000', :style => :thin}

          @bold_R = s.add_style b: true, border: {edges: [:right], :color => '000000', :style => :thin}
          @bold_T = s.add_style b: true, border: {edges: [:top], :color => '000000', :style => :thin}
          @task_title = s.add_style b: true,
                                       border: { edges: [:left, :top, :right], :color => '000000', :style => :thin},
                                       alignment: {horizontal: :center, wrap_text: true}

          @normal_L = s.add_style border: {edges: [:left], :color => '000000', :style => :thin}
          @pct_L = s.add_style border: {edges: [:left], :color => '000000', :style => :thin}, num_fmt: Axlsx::NUM_FMT_PERCENT
          @right_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}, alignment: {horizontal: :right}
          @date_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}, num_fmt: 14
          @average_style = s.add_style b: true, border: { edges: [:top], :color => '000000', :style => :medium}, format_code: "#.0"
          @average_R = s.add_style b: true, border: { edges: [:top, :right], :color => '000000', :style => :medium}, border_right: {style: :thin}, format_code: "#.0"
          @average_pct = s.add_style b: true,
                                     border: { edges: [:top], :color => '000000', :style => :medium},
                                     num_fmt: Axlsx::NUM_FMT_PERCENT

        end
      end

      def style!(hash)
        style = nil
        @package.workbook.styles{|s| style = s.add_style(hash)}
        style
      end

      def merge_and_style(sheet, range, styles)
        sheet.merge_cells(range)
        sheet[range].each{|cell| cell.style = styles}
      end

      def make_first_sheet_active
        @package.workbook.add_view active_tab: 0
      end

      def save
        success = @package.serialize(@filepath)
        raise(StandardError, "PerformanceReport::ExportCcXlsx failed") unless success
      end

      def write_data_worksheets
        @report.each do |period_report|
          write_period_worksheet(
            report: period_report,
            sheet: new_period_sheet(report: period_report, format: :percents),
            format: :percents
          )

          write_period_worksheet(
            report: period_report,
            sheet: new_period_sheet(report: period_report, format: :counts),
            format: :counts
          )
        end
      end

      def new_period_sheet(report:, format:)
        suffix = format == :counts ? " - #" : " - %"
        @package.workbook.add_worksheet(
          name: @helper.sanitized_worksheet_name(name: report[:period][:name], suffix: suffix)
        )
      end

      def write_period_worksheet(report:, sheet:, format:)

        # META INFO ROWS

        meta_rows = [
          [["Tutor Student Scores", {style: @title}]],
          [[@course_name, {style: @course_section}]],
          [["Exported #{Date.today.strftime("%m/%d/%Y")}", {style: @italic}]],
          [[""]],
          [[report[:period][:name], {style: @course_section}]],
          [[""]]
        ]

        # Normally we'd add these rows now to the sheet now; however, we want to set
        # column widths based on the widths of the non-meta rows (the data table).
        # So we hold off on adding these rows until the end of this method so that
        # Axlsx's autowidth calculations can be used.  So that cell references and
        # merged cell locations work out, add placeholder rows here that will be
        # replaced at the end.

        meta_rows.count.times { sheet.add_row }

        # TITLE COLUMNS

        task_title_columns =
          3.times.map{["", {}]} +
          [["Final Averages"],[""],[""]] +
          report[:data_headings].map do |data_heading|
            [
              data_heading[:title],
              {
                cols: 5,
                style: @task_title
              }
            ]
          end

        @helper.add_row(sheet, task_title_columns)

        due_at_columns =
          6.times.map{["", {}]} +
          report[:data_headings].map do |data_heading|
            [
              data_heading[:due_at].strftime("%m/%d/%Y"),
              {
                cols: 5,
                style: @task_title
              }
            ]
          end

        @helper.add_row(sheet, due_at_columns)

        # Have to merge vertically and style merged cells after the fact
        merge_and_style(sheet, "D7:F8",
          style!(
            b: true,
            bg_color: 'C9F0F8',
            border: { edges: [:left, :top, :right], :color => '000000', :style => :thin},
            alignment: {horizontal: :center, vertical: :center, wrap_text: true}
          )
        )

        # DATA HEADINGS

        top_data_heading_columns =
          3.times.map{["", {}]} +
          ["Homework\nScore", "Homework\nProgress", "Reading\nProgress"].map{|text| [text, style: @bold]}

        report[:data_headings].count.times do
          top_data_heading_columns.push(["Score",        {style: @bold_L}])
          top_data_heading_columns.push(["Progress",      {style: @bold}])
          top_data_heading_columns.push(["Pending Late Work", {style: @bold, cols: 3}])
        end

        @helper.add_row(sheet, top_data_heading_columns)

        bottom_data_heading_columns =
          ["First Name", "Last Name", "Student ID"].map{|text| [text, style: @bold]} +
          3.times.map{["", {}]}

        report[:data_headings].count.times do
          bottom_data_heading_columns.push(["",        {style: @bold_L}])
          bottom_data_heading_columns.push(["",      {style: @bold}])
          bottom_data_heading_columns.push(["Late Score", {style: @bold}])
          bottom_data_heading_columns.push(["Late Progress", {style: @bold}])
          bottom_data_heading_columns.push(["Last Worked", {style: @bold_R}])
        end

        @helper.add_row(sheet, bottom_data_heading_columns)

        merge_and_style(sheet, "D9:D10", style!(
          b: true, border: {edges: [:left], :color => '000000', :style => :thin},
          alignment: {horizontal: :center, vertical: :center, wrap_text: true})
        )
        merge_and_style(sheet, "E9:E10", style!(
          b: true, alignment: {horizontal: :center, vertical: :center, wrap_text: true})
        )
        merge_and_style(sheet, "F9:F10", style!(
          b: true, border: {edges: [:right], :color => '000000', :style => :thin},
          alignment: {horizontal: :center, vertical: :center, wrap_text: true})
        )

        # STUDENT DATA

        first_student_row = sheet.rows.count + 1

        students = report[:students].sort_by{|student| student[:last_name]}

        students.each do |student|
          student_columns = [
            student[:first_name],
            student[:last_name],
            student[:student_identifier],
            "tbd","tbd","tbd"
          ]

          student[:data].each do |data|
            push_score_columns(data, student_columns, format)
          end

          @helper.add_row(sheet, student_columns)
        end

        last_student_row = sheet.rows.count

        # Now that the data is in place, get what Axlsx calculated for the column widths,
        # then set all numerical columns to have a fixed width.

        data_widths = sheet.column_info.map(&:width)
        data_widths[3..-1] = data_widths[3..-1].length.times.map{15}

        sheet.column_widths(*data_widths)
      end

      def late_accepted_comment(score)
        "Late score accepted in the online view\nOriginal score on due date: #{score}"
      end

      def push_score_columns(data, columns, format)
        if data.nil? || ((total_count = data[:actual_and_placeholder_exercise_count]) == 0)
          columns.push(["", {style: @normal_L}],"","","",["", {style: @normal_R}])
        else
          on_time_correct_count = data[:correct_on_time_exercise_count]
          on_time_completed_count = data[:completed_on_time_exercise_count]

          correct_count = data[:correct_on_time_exercise_count] +
                          data[:correct_accepted_late_exercise_count]
          completed_count = data[:completed_on_time_exercise_count] +
                            data[:completed_accepted_late_exercise_count]

          some_late_work_accepted = data[:completed_accepted_late_exercise_count] != 0

          pending_late_correct_count = data[:correct_exercise_count]
          pending_late_completed_count = data[:completed_exercise_count]

          has_pending_late_work = pending_late_completed_count != completed_count

          correct_pct = correct_count * 1.0 / total_count
          completed_pct = completed_count * 1.0 / total_count

          if format == :counts
            columns.push([
              correct_count,
              {
                style: @normal_L,
                comment: some_late_work_accepted ? late_accepted_comment(on_time_correct_count) : nil
              }
            ])
            columns.push(completed_count)

            if has_pending_late_work
              columns.push(pending_late_correct_count)
              columns.push(pending_late_completed_count)
              columns.push([data[:last_worked_at], {style: @date_R}])
            else
              columns.push([""],[""],[""])
            end
          else
            columns.push([
              correct_count * 1.0 / total_count,
              {
                style: @pct_L,
                comment: some_late_work_accepted ?
                           late_accepted_comment("#{(on_time_correct_count * 100.0 / total_count).round(0)}%") : nil
              }
            ])
            columns.push([
              completed_count * 1.0 / total_count,
              {style: @pct}
            ])

            if has_pending_late_work
              columns.push([pending_late_correct_count * 1.0 / total_count, {style: @pct}])
              columns.push([pending_late_completed_count * 1.0 / total_count, {style: @pct}])
              columns.push([data[:last_worked_at], {style: @date_R}])
            else
              columns.push([""],[""],[""])
            end
          end
        end
      end


      def create_data_worksheets(performance_report, package)
        # performance_report.each do |report|
        #   package.workbook.add_worksheet(
        #     name: @helper.sanitized_worksheet_name(name: report[:period][:name])
        #   ) do |sheet|
        #     # bold = sheet.styles.add_style b: true
        #     # italic = sheet.styles.add_style i: true
        #     # pct = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT
        #     # italic_pct = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT, i: true
        #     # yellow_pct = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT, bg_color: 'FFFF93'

        #     sheet.add_row(data_headers(report[:data_headings]), style: bold)
        #     sheet.add_row(gather_due_dates(report[:data_headings]), style: italic) \
        #       unless report[:period].course.is_concept_coach

        #     sheet.add_row(gather_averages(report[:data_headings]), style: italic_pct)

        #     report.students.each do |student|
        #       styles = lateness_styles(student.data, nil, pct, yellow_pct)
        #       row = sheet.add_row(student_scores(student), style: styles)
        #       add_late_comments(sheet, student.data, row)
        #     end
        #   end
        # end
      end

      def data_headers(data_headings)
        headings = data_headings.map(&:title)
        non_data_headings + headings
      end

      def gather_due_dates(data_headings)
        due_dates = data_headings.map(&:due_at)

        collect_columns(due_dates, 'Due Date') do |d|
          d.respond_to?(:strftime) ? d.strftime("%-m/%-d/%Y") : d
        end
      end

      def gather_averages(data_headings)
        averages = data_headings.map do |heading|
          '%.2f' % heading.total_average if heading.total_average
        end

        collect_columns(averages, 'Average')
      end

      def lateness_styles(data, text, normal, late)
        collect_columns(data) { |d| d.nil? ? text : (d.late ? late : normal) }
      end

      def add_late_comments(sheet, data, row)
        data.each_with_index do |d, col|
          if d && d.late
            column = col + non_data_headings.size

            sheet.add_comment(
              ref: sheet[row.row_index][column],
              text: "Homework was worked #{time_ago_in_words(d.last_worked_at)} late",
              author: 'OpenStax',
              visible: false
            )
          end
        end
      end

      def student_scores(student)
        [student.first_name, student.last_name, student.student_identifier] + \
         student.data.map do |data|
           data ? score(data) : nil
         end
      end

      def score(data)
        case data.type
        when 'homework', 'concept_coach'
          '%.2f' % (data.correct_exercise_count/data.actual_and_placeholder_exercise_count.to_f)
        when 'reading'
          data.status.humanize
        when 'external'
          data.status == "not_started" ? "Not clicked" : "Clicked"
        else
          raise "Undefined case for data.type #{data.type} " +
                "please define it here, or use one of " +
                "homework, concept_coach, reading, external"
        end
      end

      def non_data_headings
        ['First Name', 'Last Name', 'Student ID']
      end

      def collect_columns(collection, *labels, &block)
        labels = *labels.flatten.compact

        (labels + offset_columns(labels.size) + collection).map do |item|
          block_given? ? yield(item) : item
        end
      end

      def offset_columns(subtract_amt)
        # some cases need to subtract offset
        # because they add their own columns
        # to the set

        offset_cells = non_data_headings.map { nil }

        if subtract_amt.zero?
          offset_cells
        else
          # #slice(index, length) returns new_ary
          offset_cells.first(non_data_headings.size - subtract_amt)
        end
      end
    end
  end
end
