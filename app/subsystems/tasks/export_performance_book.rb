module Tasks
  class ExportPerformanceBook
    lev_routine

    uses_routine GetCourseProfile,
      translations: { outputs: { type: :verbatim } },
      as: :get_course_profile

    uses_routine GetPerformanceBook,
      translations: { outputs: { type: :verbatim } },
      as: :get_performance_book

    protected
    def exec(role:, course:)
      run(:get_course_profile, course: course)
      run(:get_performance_book, course: course, role: role)

      Axlsx::Package.new do |file|
        file.use_shared_strings = true        # OS X Numbers interoperability
        create_summary_worksheet(file: file)
        create_data_worksheet(file: file)
        file.serialize('./tmp/sup.xlsx')
      end

      Models::PerformanceBookExport.create!(filename: 'sup')
    end

    private
    def create_summary_worksheet(file:)
      course_name = Axlsx::RichText.new
      course_name.add_run(outputs.profile.name, b: true)

      file.workbook.add_worksheet(name: 'Course Summary') do |sheet|
        sheet.add_row [course_name]
        sheet.add_row ["Generated: #{Date.today}"]
      end
    end

    def create_data_worksheet(file:)
      file.workbook.add_worksheet(name: 'Performance Book Data') do |sheet|
        sheet.add_row data_headers
        sheet.add_row display_class_averages
        outputs.performance_book.students.each do |student|
          sheet.add_row student_data(student)
        end
      end
    end

    def data_headers
      headings = outputs.performance_book.data_headings.collect(&:title)
      (['Students'] + headings).collect do |header|
        text = Axlsx::RichText.new
        text.add_run(header, b: true)
        text
      end
    end

    def display_class_averages
      averages = outputs.performance_book.data_headings.collect(&:class_average)
      (['Class average'] + averages).collect do |average|
        text = Axlsx::RichText.new
        text.add_run(average, b: true)
        text
      end
    end

    def student_data(student)
      [student.name] + student.data.collect { |data|
        [data.status, score(data)]
      }.flatten
    end

    def score(data)
      case data.type
      when 'homework'
        data.correct_exercise_count/data.exercise_count.to_f
      when 'reading'
        ''
      else
        ''
      end
    end

 #"students"=>
  #[{"name"=>"658c3baf3e25f616bdea88fcb5b04ffa",
    #"role"=>2,
    #"data"=>
     #[{"status"=>"completed",
    #"type"=>"homework",
    #"id"=>3,
    #"exercise_count"=>5,
    #"correct_exercise_count"=>5,
    #"recovered_exercise_count"=>0},
    #
    #{"status"=>"completed",
    #"type"=>"reading",
    #"id"=>1},
    #
    #{"status"=>"not_started",
    #"type"=>"homework",
    #"id"=>5,
    #"exercise_count"=>3,
    #"correct_exercise_count"=>0,
    #"recovered_exercise_count"=>0}]},
    #
   #{"name"=>"4e5fa4ca7f9f69e3daf16310a90609f8",
    #"role"=>3,
    #"data"=>
     #[{"status"=>"in_progress",
    #"type"=>"homework",
    #"id"=>4,
    #"exercise_count"=>5,
    #"correct_exercise_count"=>2,
    #"recovered_exercise_count"=>0},
    #
      #{"status"=>"in_progress",
    #"type"=>"reading",
    #"id"=>2},
    #
      #{"status"=>"not_started",
    #"type"=>"homework",
    #"id"=>6,
    #"exercise_count"=>3,
    #"correct_exercise_count"=>0,
    #"recovered_exercise_count"=>0}]}]}
  end
end
