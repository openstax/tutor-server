module Tasks
  module PerformanceReport
    class ExportXlsx
      include ActionView::Helpers::DateHelper

      lev_routine outputs: { filepath: :_self }

      protected
      def exec(profile:, report:, filename:)
        filepath = "#{filename}.xlsx"

        Axlsx::Package.new do |axlsx|
          axlsx.use_shared_strings = true # OS X Numbers interoperability
          axlsx.workbook.styles.fonts.first.name = 'Helvetica Neue'
          create_data_worksheets(report, axlsx)
          create_summary_worksheet(profile.name, axlsx)

          if axlsx.serialize(filepath)
            set(filepath: filepath)
          else
            fatal_error(code: :export_failed, message: "PerformanceReport::ExportXlsx failed")
          end
        end
      end

      private
      def create_summary_worksheet(name, package)
        package.workbook.add_worksheet(name: 'Summary') do |sheet|
          bold = sheet.styles.add_style b: true
          sheet.add_row ["#{name} Performance Report"], style: bold
          sheet.add_row [Date.today]
        end
      end

      def create_data_worksheets(performance_report, package)
        performance_report.each do |report|
          package.workbook.add_worksheet(name: report[:period][:name]) do |sheet|
            bold = sheet.styles.add_style b: true
            italic = sheet.styles.add_style i: true
            pct = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT
            italic_pct = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT, i: true
            yellow_pct = sheet.styles.add_style num_fmt: Axlsx::NUM_FMT_PERCENT, bg_color: 'FFFF93'

            sheet.add_row(data_headers(report[:data_headings]), style: bold)
            sheet.add_row(gather_due_dates(report[:data_headings]), style: italic) \
              unless report[:period].course.is_concept_coach

            sheet.add_row(gather_averages(report[:data_headings]), style: italic_pct)

            report.students.each do |student|
              styles = lateness_styles(student.data, nil, pct, yellow_pct)
              row = sheet.add_row(student_scores(student), style: styles)
              add_late_comments(sheet, student.data, row)
            end
          end
        end
      end

      def data_headers(data_headings)
        headings = data_headings.collect(&:title)
        non_data_headings + headings
      end

      def gather_due_dates(data_headings)
        due_dates = data_headings.collect(&:due_at)

        collect_columns(due_dates, 'Due Date') do |d|
          d.respond_to?(:strftime) ? d.strftime("%m/%d/%Y") : d
        end
      end

      def gather_averages(data_headings)
        averages = data_headings.map do |heading|
          '%.2f' % heading.average if heading.average
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
         student.data.collect do |data|
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

        (labels + offset_columns(labels.size) + collection).collect do |item|
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
