module Tasks
  module PerformanceReport
    class ExportXlsx

      include ::XlsxUtils

      def self.call(course_name:, report:, filename:, options: {})
        filename = "#{filename}.xlsx" unless filename.ends_with?(".xlsx")
        export = new(course_name: course_name, report: report, filepath: filename, options: options)
        export.create
        filename
      end

      # So can be called like other exporters
      def self.[](profile:, report:, filename:, options: {})
        call(course_name: profile.name, report: report, filename: filename, options: options)
      end

      def initialize(course_name:, report:, filepath:, options:)
        @course_name = course_name
        @report = report
        @filepath = filepath
        @helper = XlsxHelper.new
        @options = options
        @eq = options[:stringify_formulas] ? "" : "="
      end

      def create
        @package = Axlsx::Package.new
        @helper.standard_package_settings(@package)

        setup_styles
        remove_excluded_tasks
        handle_empty_periods
        write_data_worksheets
        make_first_sheet_active
        save
      end

      private

      def remove_excluded_tasks
        # We decided to pull out non due tasks and non exported task types here instead of
        # where the report is originally generated because that code is currently generic,
        # and leaving it serving all needs will probably help us later if we cache generated
        # report data.

        @report.each do |period_report|
          excluded_indices = []

          period_report[:data_headings].each_with_index do |heading, ii|
            if heading[:due_at] > Time.now || !%w(homework reading concept_coach).include?(heading[:type])
              excluded_indices.push(ii)
            end
          end

          period_report[:data_headings].reject!.with_index {|heading, ii| excluded_indices.include?(ii) }

          period_report[:students].each do |student|
            student[:data].reject!.with_index {|student, ii| excluded_indices.include?(ii) }
          end
        end
      end

      def handle_empty_periods
        @report.each do |period_report|
          if period_report[:students].empty?
            period_report[:students].push({first_name: "---", last_name: "EMPTY", student_identifier: "---", data: []})
          end
        end
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
                                       border: { edges: [:left, :top, :right, :bottom], :color => '000000', :style => :thin},
                                       alignment: {horizontal: :center, wrap_text: true}

          @normal_L = s.add_style border: {edges: [:left], :color => '000000', :style => :thin}
          @normal_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}
          @normal_T = s.add_style border: {edges: [:top], :color => '000000', :style => :thin}
          @pct_L = s.add_style border: {edges: [:left], :color => '000000', :style => :thin}, num_fmt: Axlsx::NUM_FMT_PERCENT
          @right_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}, alignment: {horizontal: :right}
          @date_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}, num_fmt: 14
          @average_style = s.add_style b: true, border: { edges: [:top, :bottom], :color => '000000', :style => :thin},
                                       border_top: {style: :medium}, format_code: "#", bg_color: 'F2F2F2'
          @average_R = s.add_style b: true, border: { edges: [:top, :bottom, :right], :color => '000000', :style => :thin},
                                   border_top: {style: :medium}, format_code: "#", bg_color: 'F2F2F2'
          @average_pct = s.add_style b: true,
                                     border: { edges: [:top, :bottom], :color => '000000', :style => :thin},
                                     border_top: {style: :medium},
                                     num_fmt: Axlsx::NUM_FMT_PERCENT, bg_color: 'F2F2F2'
          @average_pct_R = s.add_style b: true,
                                     border: { edges: [:top, :bottom, :right], :color => '000000', :style => :thin},
                                     border_top: {style: :medium},
                                     num_fmt: Axlsx::NUM_FMT_PERCENT, bg_color: 'F2F2F2'
          @total_style = s.add_style b: true, border: { edges: [:top, :bottom], :color => '000000', :style => :thin},
                                     format_code: "#", bg_color: 'F2F2F2'
          @total_R = s.add_style b: true, border: { edges: [:top, :bottom, :right], :color => '000000', :style => :thin},
                                 border_right: {style: :thin}, format_code: "#", bg_color: 'F2F2F2'
          @total_pct = s.add_style b: true,
                                     border: { edges: [:top, :bottom], :color => '000000', :style => :thin},
                                     num_fmt: Axlsx::NUM_FMT_PERCENT, bg_color: 'F2F2F2'
        end
      end

      def style!(hash)
        @styles ||= {}

        @styles[hash] ||= begin
          # TODO normalize incoming hash and see if it has been stored already, if
          # so save it again with the non-normalized hash

          style = nil
          @package.workbook.styles{|s| style = s.add_style(hash.dup)}
          style
        end
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
          [["Overall"],[""],[""]] +
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

        due_style = style!(border: { edges: [:right], :color => '000000', :style => :thin},
                           alignment: {horizontal: :center})
        due_at_columns =
          6.times.map{["", {}]} +
          report[:data_headings].map do |data_heading|
            [
              data_heading[:due_at].strftime("Due %-m/%-d/%Y"),
              {
                cols: 5,
                style: due_style
              }
            ]
          end

        @helper.add_row(sheet, due_at_columns)

        # Have to merge vertically and style merged cells after the fact
        @helper.merge_and_style(sheet, "D7:F8",
          style!(
            b: true,
            bg_color: 'C9F0F8',
            border: { edges: [:left, :top, :right, :bottom], :color => '000000', :style => :thin},
            alignment: {horizontal: :center, vertical: :center, wrap_text: true}
          )
        )

        # DATA HEADINGS

        top_data_heading_columns =
          3.times.map{["", {style: @normal_T}]} +
          ["Homework\nScore", "Homework\nProgress", "Reading\nProgress"].map{|text| [text, style: @bold]}

        center_bold_R_style = style!(
          b: true, border: {edges: [:right], :color => '000000', :style => :thin},
          alignment: {horizontal: :center, vertical: :center, wrap_text: true})

        report[:data_headings].count.times do
          top_data_heading_columns.push("Score")
          top_data_heading_columns.push("Progress")
          top_data_heading_columns.push(["Pending Late Work", {style: center_bold_R_style, cols: 3}])
        end

        @helper.add_row(sheet, top_data_heading_columns)

        bottom_data_heading_columns =
          ["First Name", "Last Name", "Student ID"].map{|text| [text, style: @bold]} +
          3.times.map{["", {}]}

        center_style =   style!(alignment: {horizontal: :center}) # TODO have style! cache styles
        center_style_R = style!(alignment: {horizontal: :center},
                                border: {edges: [:right], :color => '000000', :style => :thin})

        report[:data_headings].count.times do
          bottom_data_heading_columns.push("", "")
          bottom_data_heading_columns.push(["Late Score", {style: center_style}])
          bottom_data_heading_columns.push(["Late Progress", {style: center_style}])
          bottom_data_heading_columns.push(["Last Worked", {style: center_style_R}])
        end

        @helper.add_row(sheet, bottom_data_heading_columns)

        center_bold_style =
          style!(alignment: {horizontal: :center, vertical: :center, wrap_text: true}, b: true)

        # Final averages sub headings
        @helper.merge_and_style(sheet, "D9:D10", style!(
          b: true, border: {edges: [:left], :color => '000000', :style => :thin},
          alignment: {horizontal: :center, vertical: :center, wrap_text: true}))
        @helper.merge_and_style(sheet, "E9:E10", center_bold_style)
        @helper.merge_and_style(sheet, "F9:F10", center_bold_R_style)

        # "Score" and "Progress"
        report[:data_headings].count.times do |index|
          score_column = Axlsx::col_ref(6 + index * 5)
          progress_column = Axlsx::col_ref(6 + index * 5 + 1)
          @helper.merge_and_style(sheet, "#{score_column}9:#{score_column}10", center_bold_style)
          @helper.merge_and_style(sheet, "#{progress_column}9:#{progress_column}10", center_bold_style)
        end

        # STUDENT DATA

        homework_score_columns = []
        homework_progress_columns = []
        reading_progress_columns = []

        report[:data_headings].each_with_index do |heading,ii|
          case heading[:type]
          when 'reading'
            reading_progress_columns.push(Axlsx::col_ref(6+ii*5+1))
          when 'homework'
            homework_score_columns.push(Axlsx::col_ref(6+ii*5))
            homework_progress_columns.push(Axlsx::col_ref(6+ii*5+1))
          end
        end

        first_student_row = sheet.rows.count + 1

        student_data_writer = ->(students) do
          task_total_counts ||= Array.new(report[:data_headings].length)

          students.each_with_index do |student,ss|
            formula = format == :counts ? "SUM" : "AVERAGE"

            student_columns = [
              student[:first_name],
              student[:last_name],
              [student[:student_identifier], {style: @normal_R}],
              ["#{@eq}IFERROR(#{formula}(#{disjoint_range(cols: homework_score_columns, rows: first_student_row + ss)}),NA())",
               style: (format == :counts ? nil : @pct)],
              ["#{@eq}IFERROR(#{formula}(#{disjoint_range(cols: homework_progress_columns, rows: first_student_row + ss)}),NA())",
               style: (format == :counts ? nil : @pct)],
              ["#{@eq}IFERROR(#{formula}(#{disjoint_range(cols: reading_progress_columns, rows: first_student_row + ss)}),NA())",
               style: (format == :counts ? nil : @pct)]
            ]

            student[:data].each_with_index do |data,dd|
              push_score_columns(data, student_columns, format)
              (task_total_counts[dd] ||= data[:actual_and_placeholder_exercise_count]) if data.present?
            end

            @helper.add_row(sheet, student_columns)
          end

          task_total_counts
        end

        students = report[:students].sort_by{|student| student[:last_name]}
        dropped_students, active_students = students.partition{|student| student[:is_dropped]}

        task_total_counts = student_data_writer.call(active_students)

        last_student_row = sheet.rows.count

        # Now that the data is in place, get what Axlsx calculated for the column widths,
        # then set all numerical columns to have a fixed width.

        data_widths = sheet.column_info.map(&:width)
        data_widths[3..-1] = data_widths[3..-1].length.times.map{15}

        # AVERAGE ROW

        average_style = format == :counts ? @average_style : @average_pct
        average_style_R = format == :counts ? @average_R : @average_pct_R
        total_style   = format == :counts ? @total_style : @total_pct

        average_columns = [
          ["Class Average", {style: @average_style}],
          ["", {style: @average_style}],
          ["", {style: @average_R}],
          ["#{@eq}IFERROR(AVERAGEIF(D#{first_student_row}:D#{last_student_row},\"<>#N/A\"),NA())", {style: average_style}],
          ["#{@eq}IFERROR(AVERAGEIF(E#{first_student_row}:E#{last_student_row},\"<>#N/A\"),NA())", {style: average_style}],
          ["#{@eq}IFERROR(AVERAGEIF(F#{first_student_row}:F#{last_student_row},\"<>#N/A\"),NA())", {style: average_style_R}]
        ]

        report[:data_headings].count.times do |index|
          score_column = Axlsx::col_ref(6 + index * 5)
          progress_column = Axlsx::col_ref(6 + index * 5 + 1)

          score_range = "#{score_column}#{first_student_row}:#{score_column}#{last_student_row}"
          progress_range = "#{progress_column}#{first_student_row}:#{progress_column}#{last_student_row}"

          average_columns.push(["#{@eq}IFERROR(AVERAGE(#{score_range}),\"\")", {style: average_style}])
          average_columns.push(["#{@eq}IFERROR(AVERAGE(#{progress_range}),\"\")", {style: average_style}])

          average_columns.push(["", {style: @average_style}],["", {style: @average_style}],["", {style: @average_R}])
        end

        @helper.add_row(sheet, average_columns)

        # Total Possible row

        if format == :counts
          total_possible_columns = [
            ["Total Possible", {style: @total_style}],
            ["", {style: @total_style}],
            ["", {style: @total_R}],
            ["#{@eq}SUM(#{disjoint_range(cols: homework_score_columns, rows: last_student_row + 2)})", {style: @total_style}],
            ["#{@eq}SUM(#{disjoint_range(cols: homework_progress_columns, rows: last_student_row + 2)})", {style: @total_style}],
            ["#{@eq}SUM(#{disjoint_range(cols: reading_progress_columns, rows: last_student_row + 2)})", {style: @total_R}]
          ]

          task_total_counts.each do |total_count|
            total_possible_columns.push(
              [total_count, {style: total_style}],
              [total_count, {style: total_style}],
              ["", {style: @total_style}],
              ["", {style: @total_style}],
              ["", {style: @total_R}]
            )
          end

          @helper.add_row(sheet, total_possible_columns)
        end

        # Dropped students

        5.times { sheet.add_row }

        dropped_heading_style =
          style!(border: { edges: [:bottom], :color => '000000', :style => :thin},
                 alignment: {horizontal: :left},
                 b: true)
        dropped_heading_columns =
          [["DROPPED", {style: dropped_heading_style}]] +
          5.times.map{["", {style: dropped_heading_style}]} +
          (report[:data_headings].count*5).times.map {["", {style: dropped_heading_style}]}
        @helper.add_row(sheet, dropped_heading_columns)

        student_data_writer.call(dropped_students)

        dropped_footer_style = style!(border: { edges: [:top], :color => '000000', :style => :thin})
        dropped_footer_columns =
          (report[:data_headings].count*5 + 6).times.map {["", {style: dropped_footer_style}]}
        @helper.add_row(sheet, dropped_footer_columns)

        # Normalize height

        sheet.rows.each{|row| row.height = 15}

        # Now it is time to add the meta info rows that we skipped at the top of
        # this method.  The trickiness here is that in order to insert the rows
        # we need Axlsx::Row objects.  Per http://stackoverflow.com/a/24144262 one
        # way to do this is to add the rows temporarily to the sheet, delete them
        # immediately (which returns the Row object), then insert them.  We first
        # delete the placeholder rows we added up above. Since we're always
        # inserting in the first row, we reverse the meta rows so they are in the
        # right order.

        meta_rows.count.times { sheet.rows.delete_at(0) }

        meta_rows.reverse.each do |meta_row|
          @helper.add_row(sheet, meta_row)
          sheet.rows.insert 0, sheet.rows.delete_at(sheet.rows.length-1)
        end

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

    end
  end
end
