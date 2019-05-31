module SchoolDistrict
  class DeleteDistrict
    lev_routine

    protected

    def exec(district:)
      fatal_error(
        code: :district_has_schools, message: 'Cannot delete a district that has schools.'
      ) unless district.destroy
    end
  end
end
