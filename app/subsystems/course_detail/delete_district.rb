module CourseDetail
  class DeleteDistrict
    lev_routine

    protected
    def exec(id:)
      district = Models::District.find(id)

      if district.schools.empty?
        district.destroy
      else
        district.errors.add(:base, "Cannot delete a district with schools assigned")
      end
    end
  end
end
