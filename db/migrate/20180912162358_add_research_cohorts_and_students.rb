class AddResearchCohortsAndStudents < ActiveRecord::Migration[4.2]
  def change
    Research::Models::Study.includes(:cohorts, courses: [:students]).find_each do |study|
      students = study.courses.flat_map{|course| course.students }
      if students.any?
        Research::AdmitStudentsToStudies.call(students: students, studies: study)
      end
    end
  end
end
