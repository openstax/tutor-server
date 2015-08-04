module SchoolDistrict
  class DeleteDistrict
    lev_routine

    protected
    def exec(id:)
      district = Models::District.find(id)

      if district.schools.empty?
        district.destroy
      else
        fatal_error(code: :resource_has_dependencies,
                    message: "Cannot delete a district with schools assigned")
      end
    end
  end
end
