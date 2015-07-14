module CourseDetail
  class CreateSchool
    lev_routine express_output: :school

    protected
    def exec(name: 'Unnamed')
      school = Models::School.create!(name: name)

      outputs.school = { id: school.id,
                         name: school.name }
    end
  end
end
