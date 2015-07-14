module CourseDetail
  class DeleteSchool
    lev_routine

    uses_routine GetSchool, translations: { outputs: { type: :verbatim } }

    protected
    def exec(id:)
      run(:get_school, id: id)
      outputs.school.destroy
    end
  end
end
