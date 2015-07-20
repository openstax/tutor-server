module CourseDetail
  class DeleteSchool
    lev_routine

    protected
    def exec(id:)
      school = Models::School.find(id)

      if school.profiles.empty?
        school.destroy
      else
        school.errors.add(:base, "Cannot delete a school with courses assigned.")
      end
    end
  end
end
