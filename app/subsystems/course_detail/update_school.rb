module CourseDetail
  class UpdateSchool
    lev_routine express_output: :school

    protected
    def exec(id:, attributes: {})
      school = Models::School.find(id)
      school.update_attributes(attributes)
      outputs.school = { id: school.id,
                         name: school.name }
    end
  end
end
