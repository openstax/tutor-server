module Tasks
  module PerformanceReport
    class ExportCcXlsx

      def self.call(course_name:, report:, filename:)
        filename = "#{filename}.xlsx" unless filename.ends_with?(".xlsx")
        export = new(course_name: course_name, report: report, filepath: filename)
        export.create
        filename
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
        write_data_worksheets
        make_first_sheet_active
        save
      end

      protected

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
          @reading_title = s.add_style b: true,
                                       border: { edges: [:left, :top, :right], :color => '000000', :style => :thin},
                                       alignment: {horizontal: :center, wrap_text: true}
          @normal_L = s.add_style border: {edges: [:left], :color => '000000', :style => :thin}
          @pct_L = s.add_style border: {edges: [:left], :color => '000000', :style => :thin}, num_fmt: Axlsx::NUM_FMT_PERCENT
          @right_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}, alignment: {horizontal: :right}
          @date_R = s.add_style border: {edges: [:right], :color => '000000', :style => :thin}, num_fmt: 14
          @average_style = s.add_style b: true, border: { edges: [:top], :color => '000000', :style => :medium}
          @average_R = s.add_style b: true, border: { edges: [:top, :right], :color => '000000', :style => :medium}, border_right: {style: :thin}
          @average_pct = s.add_style b: true,
                                     border: { edges: [:top], :color => '000000', :style => :medium},
                                     num_fmt: Axlsx::NUM_FMT_PERCENT
        end
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

      def make_first_sheet_active
        @package.workbook.add_view active_tab: 0
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
          [["Concept Coach Student Scores", {style: @title}]],
          [["Exported #{Date.today.strftime("%m/%d/%Y")}", {style: @italic}]],
          [[""]],
          [[@course_name, {style: @course_section}]],
          [[""]],
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

        # READING TITLE COLUMNS

        reading_title_columns =
          3.times.collect{["", {style: @bold_T}]} +
          report[:data_headings].collect do |data_heading|
            [
              data_heading[:title],
              {
                cols: (format == :counts ? 4 : 3),
                style: @reading_title
              }
            ]
          end

        @helper.add_row(sheet, reading_title_columns)

        # DATA HEADINGS

        data_heading_columns =
          ["First Name", "Last Name", "Student ID"].collect{|text| [text, style: @bold]}

        report[:data_headings].count.times do
          data_heading_columns.push(["Correct",        {style: @bold_L}])
          data_heading_columns.push(["Completed",      {style: @bold}])
          data_heading_columns.push(["Total Possible", {style: @bold}]) if format == :counts
          data_heading_columns.push(["Last Worked",    {style: @bold_R}])
        end

        @helper.add_row(sheet, data_heading_columns)

        # STUDENT DATA

        first_student_row = sheet.rows.count + 1

        students = report[:students].deep_dup
        students.sort_by!{|student| student[:last_name]}

        students.each do |student|
          student_columns = [
            student[:first_name],
            student[:last_name],
            student[:student_identifier]
          ]

          student[:data].each do |data|
            if data
              correct_count = data[:correct_exercise_count]
              completed_count = data[:completed_exercise_count]
              total_count = data[:actual_and_placeholder_exercise_count]

              correct_pct = correct_count * 1.0 / total_count
              completed_pct = completed_count * 1.0 / total_count

              if format == :counts
                student_columns.push([
                  correct_count,
                  {
                    style: @normal_L,
                    comment: "Correct: #{(correct_pct*100).round(0)} Completed: #{(completed_pct*100).round(0)}"
                  }
                ])
                student_columns.push(completed_count)
                student_columns.push(total_count)
              else
                student_columns.push([
                  correct_pct,
                  {
                    style: @pct_L,
                    comment: "Correct: #{correct_count} " \
                             "Completed: #{completed_count} " \
                             "Total Possible: #{total_count}"
                  }
                ])
                student_columns.push([
                  completed_pct,
                  {style: @pct}
                ])
              end
              student_columns.push([data[:last_worked_at], {style: @date_R}])
            else
              student_columns.push(["", {style: @normal_L}],"")
              student_columns.push("") if format == :counts
              student_columns.push(["Not Started", {style: @right_R}])
            end
          end

          @helper.add_row(sheet, student_columns)
        end

        last_student_row = sheet.rows.count

        # Now that the data is in place, get what Axlsx calculated for the column widths,
        # then set all numerical columns to have a fixed width.

        data_widths = sheet.column_info.collect(&:width)
        data_widths[3..-1] = data_widths[3..-1].length.times.map{15}

        # AVERAGE ROW

        average_columns = [
          ["Class Average", {style: @average_style}],
          ["", {style: @average_style}],
          ["", {style: @average_R}]
        ]

        report[:data_headings].count.times do |index|
          first_column = index * (format == :counts ? 4 : 3) + 3
          average_style = format == :counts ? @average_style : @average_pct

          correct_range =
            XlsxHelper.cell_ref(row: first_student_row, column: first_column) + ":" +
            XlsxHelper.cell_ref(row: last_student_row, column: first_column)

          completed_range =
            XlsxHelper.cell_ref(row: first_student_row, column: first_column+1) + ":" +
            XlsxHelper.cell_ref(row: last_student_row, column: first_column+1)

          average_columns.push(["=AVERAGE(#{correct_range})", {style: average_style}])
          average_columns.push(["=AVERAGE(#{completed_range})", {style: average_style}])

          if format == :counts
            total_range =
              XlsxHelper.cell_ref(row: first_student_row, column: first_column+2) + ":" +
              XlsxHelper.cell_ref(row: last_student_row, column: first_column+2)

            average_columns.push(["=AVERAGE(#{total_range})", {style: average_style}])
          end

          average_columns.push(["", {style: @average_R}])
        end

        @helper.add_row(sheet, average_columns)

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

        # Now that all data has been added, we set the column widths.

        sheet.column_widths(*data_widths)

      end # end write_period_worksheet

      def save
        success = @package.serialize(@filepath)
        raise(StandardError, "PerformanceReport::ExportCcXlsx failed") unless success
      end

    end
  end
end
