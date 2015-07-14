module CourseDetail
  class ListSchools
    lev_routine express_output: :schools

    protected
    def exec
      schools = Models::School.all
      outputs.schools = schools.collect do |school|
        { id: school.id,
          name: school.name }
      end
    end
  end
end
