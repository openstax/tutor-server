class AddResearchCohortsAndStudents < ActiveRecord::Migration
  def change
    Research::Models::Study.includes(:cohorts, courses: [:students]).find_each do |study|
      study.cohorts.create(name: "default") if study.cohorts.empty?
      students = study.courses.flat_map{|course| course.students }
      if students.any?
        Research::AdmitStudentsToStudies.call(students: students, studies: study)
      end
    end
  end
end
