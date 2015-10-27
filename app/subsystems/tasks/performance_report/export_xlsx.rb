module Tasks
  module PerformanceReport
    class ExportXlsx
      include ActionView::Helpers::DateHelper

      lev_routine express_output: :filepath

      protected
      def exec(profile:, report:, filename:)
        filepath = "#{filename}.xlsx"

        Axlsx::Package.new do |axlsx|
          axlsx.use_shared_strings = true # OS X Numbers interoperability
          axlsx.workbook.styles.fonts.first.name = 'Helvetica Neue'
          create_data_worksheets(report, axlsx)
          create_summary_worksheet(profile.name, axlsx)

          if axlsx.serialize(filepath)
            outputs.filepath = filepath
          else
            fatal_error(code: :export_failed,
                        message: "PerformanceReport::ExportXlsx failed")
          end
        end
      end

      private
      def create_summary_worksheet(name, package)
        package.workbook.add_worksheet(name: 'Summary') do |sheet|
          sheet.add_row [bold_text("#{name} Performance Report")]
          sheet.add_row [Date.today]
        end
      end

      def create_data_worksheets(performance_report, package)
        performance_report.each do |report|
          package.workbook.add_worksheet(name: report[:period][:name]) do |sheet|
            sheet.add_row(data_headers(report[:data_headings]))
            sheet.add_row(gather_due_dates(report[:data_headings]))

            sheet.add_row(gather_averages(report[:data_headings]))

            report.students.each_with_index do |student, row|
              styles = lateness_styles(student.data, sheet)
              sheet.add_row(student_scores(student), style: styles)
              add_late_comments(sheet, student.data, row)
            end

            percent = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT

            report[:data_headings].each.with_index do |heading, i|
              sheet.col_style(i + 1, percent, row_offset: 2) if heading.average
            end
          end
        end
      end

      def data_headers(data_headings)
        headings = data_headings.collect(&:title)
        (non_data_headings + headings).collect { |header| bold_text(header) }
      end

      def gather_due_dates(data_headings)
        due_dates = data_headings.collect(&:due_at)

        collect_columns(due_dates, 'Due Date') do |d|
          d = d.respond_to?(:strftime) ? d.strftime("%m/%d/%Y") : d
          italic_text(d)
        end
      end

      def gather_averages(data_headings)
        averages = data_headings.map do |heading|
          '%.2f' % heading.average if heading.average
        end

        collect_columns(averages, 'Average') { |average| italic_text(average) }
      end

      def lateness_styles(data, worksheet)
        collect_columns(data) do |d|
          worksheet.styles.add_style bg_color: 'FFFF93' if d && d.late
        end
      end

      def add_late_comments(sheet, data, row)
        data.each_with_index do |d, col|
          if d && d.late
            column = col + non_data_headings.size
            row_offset  = row + 4 # there are 4 rows of headings

            sheet.add_comment(
              ref: TwoDMatrixHelper.find_cell(row: row_offset, column: column),
              text: "Homework was worked #{time_ago_in_words(d.last_worked_at)} late",
              author: 'OpenStax',
              visible: false
            )
          end
        end
      end

      def student_scores(student)
        [student.first_name, student.last_name] + student.data.collect do |data|
          data ? score(data) : nil
        end
      end

      def score(data)
        case data.type
        when 'homework'
          '%.2f' % (data.correct_exercise_count/data.actual_and_placeholder_exercise_count.to_f)
        when 'reading'
          data.status.humanize
        when 'external'
          data.status == "not_started" ? "Not clicked" : "Clicked"
        else
          raise "Undefined case for data.type #{data.type} " +
                "please define it here, or use one of " +
                "homework, reading, external"
        end
      end

      def bold_text(content)
        text = Axlsx::RichText.new
        text.add_run(content, b: true)
        text
      end

      def italic_text(content)
        text = Axlsx::RichText.new
        text.add_run(content, i: true)
        text
      end

      def non_data_headings
        ['First Name', 'Last Name']
      end

      def collect_columns(collection, *labels, &block)
        labels = *labels.flatten.compact

        (labels + offset_columns(labels.size) + collection).collect do |item|
          yield(item)
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
          offset_cells.slice(offset_cells.index(nil), subtract_amt)
        end
      end
    end
  end
end
