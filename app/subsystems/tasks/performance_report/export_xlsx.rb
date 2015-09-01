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
          create_summary_worksheet(profile.name, axlsx)
          create_data_worksheets(report, axlsx)

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
              styles = cell_styles(student.data, sheet)
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
        (['First Name', 'Last Name'] + headings).collect { |header| bold_text(header) }
      end

      def gather_due_dates(data_headings)
        due_dates = data_headings.collect(&:due_at)

        [italic_text('Due Date')] + due_dates.collect do |due_date|
          italic_text(due_date.strftime("%m/%d/%Y"))
        end
      end

      def gather_averages(data_headings)
        averages = data_headings.map do |heading|
          '%.2f' % heading.average if heading.average
        end

        (['Average'] + averages).collect { |average| italic_text(average) }
      end

      def cell_styles(data, worksheet)
        # first two cells are student first/last name
        [nil, nil] + data.map do |d|
          worksheet.styles.add_style bg_color: 'FFFF93' if !d.nil? && d.late
        end
      end

      def add_late_comments(sheet, data, row)
        data.each_with_index do |d, col|
          next if d.nil? || !d.late
          ref = "#{('C'..'Z').to_a[col]}#{row + 4}" # forms something like 'D5'
          sheet.add_comment ref: ref,
            text: "Homework was worked #{time_ago_in_words(d.last_worked_at)} late",
            author: 'OpenStax',
            visible: false
        end
      end

      def student_scores(student)
        [student.first_name, student.last_name] + student.data.collect do |data|
          data.nil? ? nil : score(data)
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
    end
  end
end
