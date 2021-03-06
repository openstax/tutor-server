module Tasks
  module PerformanceReport
    class ExportXlsx
      lev_routine transaction: :no_transaction

      include ::XlsxUtils

      protected

      def exec(course:, report:, filename:, options: {})
        @course = course
        @report = report
        @filename = filename.ends_with?(".xlsx") ? filename : "#{filename}.xlsx"
        @helper = XlsxHelper.new
        @options = options
        @eq = options[:stringify_formulas] ? "" : "="

        create_export

        outputs.filename = @filename
      end

      def create_export
        @package = Axlsx::Package.new
        @helper.standard_package_settings(@package)

        setup_styles
        remove_excluded_tasks
        handle_empty_periods
        write_data_worksheets
        make_first_sheet_active
        save
      end

      def remove_excluded_tasks
        # We decided to pull out non due tasks and non exported task types here instead of where
        # the report is originally generated because that code is currently generic, and leaving
        # it serving all needs will probably help us later if we cache generated report data

        @report.each do |period_report|
          excluded_indices = []

          period_report[:data_headings].each_with_index do |heading, ii|
            if heading[:due_at] > Time.current ||
               !%w(homework reading concept_coach).include?(heading[:type])
              excluded_indices.push(ii)
            end
          end

          period_report[:data_headings].reject!.with_index do |heading, ii|
            excluded_indices.include?(ii)
          end

          period_report[:students].each do |student|
            student[:data].reject!.with_index { |student, ii| excluded_indices.include?(ii) }
          end
        end
      end

      def handle_empty_periods
        @report.each do |period_report|
          if period_report[:students].empty?
            period_report[:students].push(
              first_name: "---", last_name: "EMPTY", student_identifier: "---", data: []
            )
          end
        end
      end

      def setup_styles
        @package.workbook.styles do |s|
          @title = s.add_style sz: 16

          @course_section = s.add_style sz: 14

          @bold_L = s.add_style(b: true, border: { edges: [:left], color: '000000', style: :thin })
          @bold = s.add_style b: true
          @bold_R = s.add_style(b: true, border: { edges: [:right], color: '000000', style: :thin })
          @italic = s.add_style i: true

          @dec_format = "0.0#;(0.0#);0"

          @overall = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right], color: '000000', style: :thin },
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )

          @task_title = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right, :bottom], color: '000000', style: :thin },
            alignment: { horizontal: :center, wrap_text: true }
          )

          @due_at = s.add_style(
            border: { edges: [:left, :right], color: '000000', style: :thin },
            alignment: { horizontal: :center }
          )

          @bold_heading_L = s.add_style(
            b: true,
            border: { edges: [:left], color: '000000', style: :thin },
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )
          @bold_heading = s.add_style(
            b: true,
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )
          @bold_heading_R = s.add_style(
            b: true,
            border: { edges: [:right], color: '000000', style: :thin },
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )
          @bold_heading_LR = s.add_style(
            b: true,
            border: { edges: [:left, :right], color: '000000', style: :thin },
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )

          @heading = s.add_style(alignment: { horizontal: :center })
          @heading_R = s.add_style(
            alignment: { horizontal: :center },
            border: { edges: [:right], color: '000000', style: :thin }
          )

          @normal_L = s.add_style border: { edges: [:left], color: '000000', style: :thin }
          @normal_LT = s.add_style border: { edges: [:left, :top], color: '000000', style: :thin }
          @normal_LR = s.add_style(
            border: { edges: [:left, :right], color: '000000', style: :thin },
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )
          @normal_T = s.add_style border: { edges: [:top], color: '000000', style: :thin }
          @normal_TR = s.add_style border: { edges: [:top, :right], color: '000000', style: :thin }
          @normal_R = s.add_style border: { edges: [:right], color: '000000', style: :thin }

          @pct_L = s.add_style(
            border: { edges: [:left], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT
          )
          @pct_LR = s.add_style(
            border: { edges: [:left, :right], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            alignment: { horizontal: :center, vertical: :center, wrap_text: true }
          )
          @pct = s.add_style num_fmt: Axlsx::NUM_FMT_PERCENT
          @pct_R = s.add_style(
            border: { edges: [:right], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT
          )

          @overall_L = s.add_style(
            b: true,
            border: { edges: [:left, :top, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            bg_color: 'F2F2F2'
          )
          @overall = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            bg_color: 'F2F2F2'
          )
          @overall_R = s.add_style(
            b: true,
            border: { edges: [:top, :right, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            bg_color: 'F2F2F2'
          )

          @average_num_L = s.add_style(
            b: true,
            border: { edges: [:left, :top, :bottom], color: '000000', style: :thin },
            format_code: @dec_format,
            bg_color: 'F2F2F2'
          )
          @average_num_LR = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right, :bottom], color: '000000', style: :thin },
            format_code: @dec_format,
            bg_color: 'F2F2F2',
            alignment: { horizontal: :center }
          )
          @average_num_LRT = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            format_code: @dec_format,
            bg_color: 'F2F2F2',
            alignment: { horizontal: :center }
          )
          @average_num = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            format_code: @dec_format,
            bg_color: 'F2F2F2'
          )
          @average_num_T = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            format_code: @dec_format,
            bg_color: 'F2F2F2'
          )
          @average_num_R = s.add_style(
            b: true,
            border: { edges: [:top, :right, :bottom], color: '000000', style: :thin },
            format_code: @dec_format,
            bg_color: 'F2F2F2'
          )

          @average_pct_L = s.add_style(
            b: true,
            border: { edges: [:left, :top, :bottom], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            bg_color: 'F2F2F2'
          )
          @average_pct_LR = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right, :bottom], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            bg_color: 'F2F2F2',
            alignment: { horizontal: :center }
          )
          @average_pct_LRT = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            bg_color: 'F2F2F2',
            alignment: { horizontal: :center }
          )
          @average_pct = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            bg_color: 'F2F2F2'
          )
          @average_pct_T = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            border_top: { style: :medium },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            bg_color: 'F2F2F2'
          )
          @average_pct_R = s.add_style(
            b: true,
            border: { edges: [:top, :right, :bottom], color: '000000', style: :thin },
            num_fmt: Axlsx::NUM_FMT_PERCENT,
            bg_color: 'F2F2F2'
          )

          @total_L = s.add_style(
            b: true,
            border: { edges: [:left, :top, :bottom], color: '000000', style: :thin },
            border_right: { style: :thin },
            format_code: "0",
            bg_color: 'F2F2F2'
          )
          @total_LR = s.add_style(
            b: true,
            border: { edges: [:left, :top, :right, :bottom], color: '000000', style: :thin },
            alignment: { horizontal: :center },
            border_right: { style: :thin },
            format_code: @dec_format,
            bg_color: 'F2F2F2'
          )
          @total = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            format_code: "0",
            bg_color: 'F2F2F2'
          )
          @total_R = s.add_style(
            b: true,
            border: { edges: [:top, :right, :bottom], color: '000000', style: :thin },
            border_right: { style: :thin },
            format_code: "0",
            bg_color: 'F2F2F2'
          )

          @minmax_L = s.add_style(
            b: true,
            border: { edges: [:left, :top, :bottom], color: '000000', style: :thin },
            border_right: { style: :thin },
            format_code: "0",
            bg_color: 'F2F2F2'
          )
          @minmax = s.add_style(
            b: true,
            border: { edges: [:top, :bottom], color: '000000', style: :thin },
            format_code: "0",
            bg_color: 'F2F2F2'
          )
          @minmax_R = s.add_style(
            b: true,
            border: { edges: [:top, :right, :bottom], color: '000000', style: :thin },
            border_right: { style: :thin },
            format_code: "0",
            bg_color: 'F2F2F2'
          )

          @dropped_heading = s.add_style(
            border: { edges: [:bottom], color: '000000', style: :thin },
            alignment: { horizontal: :left },
            b: true
          )
          @dropped_footer = s.add_style(border: { edges: [:top], color: '000000', style: :thin })
        end
      end

      def make_first_sheet_active
        @package.workbook.add_view active_tab: 0
      end

      def save
        success = @package.serialize(@filename)
        raise(StandardError, "PerformanceReport::ExportXlsx failed") unless success
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
            sheet: new_period_sheet(report: period_report, format: :points),
            format: :points
          )
        end
      end

      def new_period_sheet(report:, format:)
        suffix = format == :points ? " - #" : " - %"
        @package.workbook.add_worksheet(
          name: @helper.sanitized_worksheet_name(name: report[:period][:name], suffix: suffix)
        )
      end

      def write_period_worksheet(report:, sheet:, format:)

        # META INFO ROWS

        meta_rows = [
          [["Tutor Student Scores", style: @title]],
          [[@course.name, style: @course_section]],
          [["Exported #{@course.time_zone.today.strftime("%m/%d/%Y")}", style: @italic]],
          [""],
          [[report[:period][:name], style: @course_section]],
          [""]
        ]

        # Normally we'd add these rows now to the sheet now; however, we want to set
        # column widths based on the widths of the non-meta rows (the data table).
        # So we hold off on adding these rows until the end of this method so that
        # Axlsx's autowidth calculations can be used.  So that cell references and
        # merged cell locations work out, add placeholder rows here that will be
        # replaced at the end.

        meta_rows.count.times { sheet.add_row }

        num_student_info_columns = 3
        num_average_columns = format == :points ? 0 : 3
        num_non_task_columns = num_student_info_columns + num_average_columns
        num_columns_per_task = 1

        # TITLE COLUMNS

        task_title_columns = num_student_info_columns.times.map { "" }
        task_title_columns += ["Averages","",""] if format != :points
        task_title_columns += report[:data_headings].map do |data_heading|
          [ data_heading[:title], cols: num_columns_per_task, style: @task_title ]
        end

        @helper.add_row(sheet, task_title_columns)

        due_at_columns =
          num_non_task_columns.times.map { "" } +
          report[:data_headings].map do |data_heading|
            [
              data_heading[:due_at].strftime("Due %-m/%-d/%Y"),
              cols: num_columns_per_task,
              style: @due_at
            ]
          end

        @helper.add_row(sheet, due_at_columns)

        # Have to merge vertically and style merged cells after the fact
        @helper.merge_and_style(
          sheet,
          "D7:F8",
          @overall
        ) if format != :points

        # DATA HEADINGS

        top_data_heading_columns = [
          ["", style: @normal_LT],
          ["", style: @normal_T],
          ["", style: @normal_TR]
        ]
        top_data_heading_columns += [
          "Course Average*", "Homework Averages", "Reading Averages"
        ].map { |text| [text] } if format != :points

        report[:data_headings].count.times do
          top_data_heading_columns.push("Score")
        end

        @helper.add_row(sheet, top_data_heading_columns)

        bottom_data_heading_columns = [
          ["First Name", style: @bold_L],
          ["Last Name", style: @bold],
          ["Student ID", style: @bold_R]
        ]
        bottom_data_heading_columns += num_average_columns.times.map { "" }

        report[:data_headings].count.times do
          bottom_data_heading_columns.push("", "")
        end

        @helper.add_row(sheet, bottom_data_heading_columns)

        # Final averages sub headings
        if format != :points
          @helper.merge_and_style(sheet, "D9:D10", @bold_heading_L)
          @helper.merge_and_style(sheet, "E9:E10", @bold_heading)
          @helper.merge_and_style(sheet, "F9:F10", @bold_heading_R)
        end

        # "Score"
        report[:data_headings].count.times do |index|
          score_column = Axlsx::col_ref(num_non_task_columns + index * num_columns_per_task)
          @helper.merge_and_style(sheet, "#{score_column}9:#{score_column}10", @bold_heading_LR)
        end

        # STUDENT DATA

        homework_score_columns = []
        reading_score_columns = []

        report[:data_headings].each_with_index do |heading, ii|
          case heading[:type]
          when 'reading'
            reading_score_columns.push(
              Axlsx::col_ref(num_non_task_columns + ii * num_columns_per_task)
            )
          when 'homework'
            homework_score_columns.push(
              Axlsx::col_ref(num_non_task_columns + ii * num_columns_per_task)
            )
          end
        end


        student_data_writer = ->(students) do
          row_index = sheet.rows.count

          students.each_with_index do |student|
            row_index += 1
            student_columns = [
              [student[:first_name].to_s.gsub('=', ''), style: @normal_L],
              student[:last_name].to_s.gsub('=', ''),
              [student[:student_identifier].to_s.gsub('=', ''), style: @normal_R]
            ]
            sum_formula = []
            sum_formula << "#{@course.homework_weight}*#{
              Axlsx::cell_r(num_student_info_columns + 1, row_index - 1)
            }" if @course.homework_weight > 0
            sum_formula << "#{@course.reading_weight}*#{
              Axlsx::cell_r(num_student_info_columns + 2, row_index - 1)
            }" if @course.reading_weight > 0
            student_columns += [
              [
                "#{@eq}IFERROR(SUM(#{sum_formula.join(',')}),0)", style: @pct_L
              ],
              [
                "#{@eq}IFERROR(AVERAGE(#{
                  disjoint_range(cols: homework_score_columns, rows: row_index)
                }),0)", style: @pct
              ],
              [
                "#{@eq}IFERROR(AVERAGE(#{
                  disjoint_range(cols: reading_score_columns, rows: row_index)
                }),0)", style: @pct
              ]
            ] if format != :points

            student[:data].each_with_index do |data,dd|
              push_score_columns(data, student_columns, format)
            end

            @helper.add_row(sheet, student_columns)
          end
        end  ### END OF student_data_writer lambda

        students = report[:students].sort_by { |student| (student[:last_name] || '').downcase }
        dropped_students, active_students = students.partition { |student| student[:is_dropped] }

        first_student_row = sheet.rows.count + 1
        student_data_writer.call(active_students)

        last_student_row = sheet.rows.count

        # Now that the data is in place, get what Axlsx calculated for the column widths,
        # then set all numerical columns to have a fixed width.

        data_widths = sheet.column_info.map(&:width)
        data_widths[num_student_info_columns..num_non_task_columns-1] =
          num_average_columns.times.map { 18.5 }
        data_widths[num_non_task_columns..-1] = data_widths[num_non_task_columns..-1].map { 16 }

        # Class Average

        average_style_L = format == :points ? @average_num_L : @average_pct_L
        average_style = format == :points ? @average_num : @average_pct
        average_style_T = format == :points ? @average_num_T : @average_pct_T
        average_style_R = format == :points ? @average_num_R : @average_pct_R
        average_style_LR = format == :points ? @average_num_LR : @average_pct_LR
        average_style_LRT = format == :points ? @average_num_LRT : @average_pct_LRT

        average_columns = [
          ["Class Average", style: @overall_L],
          ["", style: @overall],
          ["", style: @overall_R]
        ]
        average_columns += [
          [
            "#{@eq}IFERROR(AVERAGEIF(D#{first_student_row}:D#{last_student_row},\"<>#N/A\"),0)",
            style: average_style_T
          ],
          [
            "#{@eq}IFERROR(AVERAGEIF(E#{first_student_row}:E#{last_student_row},\"<>#N/A\"),0)",
            style: average_style_T
          ],
          [
            "#{@eq}IFERROR(AVERAGEIF(F#{first_student_row}:F#{last_student_row},\"<>#N/A\"),0)",
            style: average_style_T
          ]
        ] if format != :points

        report[:data_headings].count.times do |index|
          score_column = Axlsx::col_ref(num_non_task_columns + index * num_columns_per_task)
          score_range = "#{score_column}#{first_student_row}:#{score_column}#{last_student_row}"

          average_columns.push(
            ["#{@eq}IFERROR(AVERAGE(#{score_range}),\"\")", style: average_style_LRT]
          )
        end

        @helper.add_row(sheet, average_columns)

        # Minimum Score

        min_columns = [
          ["Minimum Score", style: @minmax_L],
          ["", style: @minmax],
          ["", style: @minmax_R]
        ]

        unless format == :points
          min_columns += [
            [
              "#{@eq}IFERROR(MIN(D#{first_student_row}:D#{last_student_row}),0)",
              style: average_style_L
            ],
            [
              "#{@eq}IFERROR(MIN(E#{first_student_row}:E#{last_student_row}),0)",
              style: average_style
            ],
            [
              "#{@eq}IFERROR(MIN(F#{first_student_row}:F#{last_student_row}),0)",
              style: average_style
            ]
          ]
        end

        report[:data_headings].count.times do |index|
          min_column = Axlsx::col_ref(num_non_task_columns + index * num_columns_per_task)
          min_range = "#{min_column}#{first_student_row}:#{min_column}#{last_student_row}"

          min_columns.push(
            ["#{@eq}IFERROR(MIN(#{min_range}),\"\")", style: average_style_LR]
          )
        end

        @helper.add_row(sheet, min_columns)

        # Maximum Score

        max_columns = [
          ["Maximum Score", style: @minmax_L],
          ["", style: @minmax],
          ["", style: @minmax_R]
        ]

        unless format == :points
          max_columns += [
            [
              "#{@eq}IFERROR(MAX(D#{first_student_row}:D#{last_student_row}),0)",
              style: average_style_L
            ],
            [
              "#{@eq}IFERROR(MAX(E#{first_student_row}:E#{last_student_row}),0)",
              style: average_style
            ],
            [
              "#{@eq}IFERROR(MAX(F#{first_student_row}:F#{last_student_row}),0)",
              style: average_style
            ]
          ]
        end

        report[:data_headings].count.times do |index|
          max_column = Axlsx::col_ref(num_non_task_columns + index * num_columns_per_task)
          max_range = "#{max_column}#{first_student_row}:#{max_column}#{last_student_row}"

          max_columns.push(
            ["#{@eq}IFERROR(MAX(#{max_range}),\"\")", style: average_style_LR]
          )
        end

        @helper.add_row(sheet, max_columns)

        # Total Possible row

        if format == :points
          total_possible_columns = [
            ["Total Possible", style: @total_L],
            ["", style: @total],
            ["", style: @total_R]
          ]

          report[:data_headings].each do |heading|
            total_possible_columns.push([heading[:available_points], style: @total_LR])
          end

          @helper.add_row(sheet, total_possible_columns)
        end

        # Merge average row labels so they don't get cut off
        1.upto(4) do |i|
          break if i == 4 && format != :points
          sheet.merge_cells("A#{last_student_row + i}:C#{last_student_row + i}")
        end

        # Dropped students

        5.times { sheet.add_row }

        dropped_heading_columns =
          [["DROPPED", style: @dropped_heading]] +
          (
            num_non_task_columns - 1 + report[:data_headings].count * num_columns_per_task
          ).times.map { ["", style: @dropped_heading] }
        @helper.add_row(sheet, dropped_heading_columns)

        student_data_writer.call(dropped_students)

        dropped_footer_columns =
          (num_non_task_columns + report[:data_headings].count * num_columns_per_task).times.map do
            ["", style: @dropped_footer]
          end
        @helper.add_row(sheet, dropped_footer_columns)

        # Course average explanation

        if format != :points
          3.times { sheet.add_row }

          @helper.add_row(
            sheet,
            [[
              "* Course average = "\
              "#{@course.homework_weight * 100}% Homework average + "\
              "#{@course.reading_weight * 100}% Reading average. "\
              "You can set the course average weight in OpenStax Tutor.",
              style: @italic
            ]]
          )
        end

        # Normalize height
        sheet.rows.each { |row| row.height = 15 }

        # Make class name height taller so long titles can wrap
        sheet.rows[6].height = 30

        # Now it is time to add the meta info rows that we skipped at the top of
        # this method. The trickiness here is that in order to insert the rows
        # we need Axlsx::Row objects. Per http://stackoverflow.com/a/24144262 one
        # way to do this is to add the rows temporarily to the sheet, delete them
        # immediately (which returns the Row object), then insert them. We first
        # delete the placeholder rows we added up above. Since we're always inserting
        # in the first row, we reverse the meta rows so they are in the right order.

        meta_rows.count.times { sheet.rows.delete_at(0) }

        meta_rows.reverse.each do |meta_row|
          @helper.add_row(sheet, meta_row)
          sheet.rows.insert 0, sheet.rows.delete_at(sheet.rows.length-1)
        end

        # Freeze the student info columns and the task info rows
        sheet.sheet_view.pane do |pane|
          pane.top_left_cell = "D11"
          pane.state = :frozen
          pane.y_split = 10
          pane.x_split = 3
          pane.active_pane = :bottom_right
        end

        sheet.column_widths(*data_widths)
      end

      def push_score_columns(data, columns, format)
        if data.nil? || data[:actual_and_placeholder_exercise_count] == 0
          columns.push(
            ["", style: @normal_LR]
          )
        else
          if format == :points
            columns.push([
              (data[:published_points] ? "=ROUND(#{data[:published_points]}, 2)" : 0), { style: @normal_LR }
            ])
          else
            columns.push([
              data[:published_score] || 0, { style: @pct_LR }
            ])
          end
        end
      end
    end
  end
end
