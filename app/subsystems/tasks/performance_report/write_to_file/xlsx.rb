module Tasks
  module PerformanceReport
    module WriteToFile
      class Xlsx
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
                          message: "PerformanceReport::WriteToFile::Xlsx failed")
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
              report.students.each do |student|
                sheet.add_row(student_data(student))
              end
            end
          end
        end

        def data_headers(data_headings)
          headings = data_headings.collect(&:title)
          (['Students'] + headings).collect { |header| bold_text(header) }
        end

        def gather_due_dates(data_headings)
          due_dates = data_headings.collect(&:due_at)
          (['Due Date'] + due_dates).collect { |due_date| italic_text(due_date) }
        end

        def gather_averages(data_headings)
          averages = data_headings.collect(&:average)
          (['Average'] + averages).collect { |average| italic_text(average) }
        end

        def student_data(student)
          [student.name] + student.data.collect { |data| score(data) }
        end

        def score(data)
          case data.type
          when 'homework'
            data.correct_exercise_count/data.exercise_count.to_f
          when 'reading'
            data.status.humanize
          else
            raise "Undefined case for data.type #{data.type} " +
                  "please define it here, or use one of " +
                  "homework, reading"
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
end
