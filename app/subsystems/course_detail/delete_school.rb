module CourseDetail
  class DeleteSchool
    lev_routine

    protected
    def exec(id:)
      school = Models::School.find(id)

      if school.profiles.empty?
        school.destroy
      else
        fatal_error(code: :resource_has_dependencies,
                    message: "Cannot delete a school with courses associated.")
      end
    end
  end
end
