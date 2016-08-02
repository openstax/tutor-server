module SchoolDistrict
  class DeleteDistrict
    lev_routine

    protected

    def exec(district:)
      if district.destroy
        Legal::ForgetAbout[item: district]
      else
        fatal_error code: :district_has_schools,
                    message: 'Cannot delete a district that has schools.'
      end
    end
  end
end
