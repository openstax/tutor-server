module Tasks
  class ExportPerformanceBook
    lev_routine

    uses_routine GetCourseProfile,
      translations: { outputs: { type: :verbatim } },
      as: :get_course_profile

    uses_routine GetPerformanceBook,
      translations: { outputs: { type: :verbatim } },
      as: :get_performance_book

    uses_routine CreatePerformanceBookExport,
      translations: { outputs: { type: :verbatim } },
      as: :create_performance_book_export

    protected
    def exec(role:, course:)
      run(:get_course_profile, course: course)
      run(:get_performance_book, course: course, role: role)

      Axlsx::Package.new do |file|
        file.use_shared_strings = true # OS X Numbers interoperability
        file.workbook.styles.fonts.first.name = 'Helvetica Neue'
        create_summary_worksheet(file: file)
        create_data_worksheet(file: file)
        file.serialize(tmp_file_path)
      end

      run(:create_performance_book_export, filepath: tmp_file_path,
                                           course: course,
                                           role: role)
    end

    private
    def create_summary_worksheet(file:)
      file.workbook.add_worksheet(name: 'Course Summary') do |sheet|
        sheet.add_row [bold_text("#{outputs.profile.name} Performance Book")]
        sheet.add_row [Date.today]
      end
    end

    def create_data_worksheet(file:)
      file.workbook.add_worksheet(name: 'Student Performance') do |sheet|
        sheet.add_row(data_headers)
        sheet.add_row(gather_class_averages)
        outputs.performance_book.students.each do |student|
          sheet.add_row student_data(student)
        end
      end
    end

    def data_headers
      headings = outputs.performance_book.data_headings.collect(&:title)
      (['Students'] + headings).collect { |header| bold_text(header) }
    end

    def gather_class_averages
      averages = outputs.performance_book.data_headings.collect(&:class_average)
      (['Class average'] + averages).collect { |average| bold_text(average) }
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

    def tmp_file_path
      ['./tmp/', generate_file_name, '.xlsx'].join('')
    end

    def generate_file_name
      [outputs.profile.name, '_Performance_',
       Time.current.strftime("%Y%m%d-%H%M%S")].join('')
    end
  end
end
