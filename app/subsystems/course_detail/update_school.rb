module CourseDetail
  class UpdateSchool
    lev_routine express_output: :school

    uses_routine GetSchool, translations: { outputs: { type: :verbatim } }

    protected
    def exec(id:, attributes: {})
      run(:get_school, id: id)

      outputs.school.update_attributes(attributes)

      outputs.school = { id: outputs.school.id,
                         name: outputs.school.name }
    end
  end
end
