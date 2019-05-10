module SchoolDistrict
  class DeleteSchool
    lev_routine

    protected

    def exec(school:)
      fatal_error(
        code: :school_has_courses, message: 'Cannot delete a school that has courses.'
      ) unless school.destroy
    end
  end
end
