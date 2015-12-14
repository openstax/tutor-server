module SchoolDistrict
  class DeleteDistrict
    lev_routine

    protected
    def exec(id:)
      district = Models::District.find(id)
      district.destroy
      transfer_errors_from(district, {type: :verbatim}, true)

      Legal::ForgetAbout.call(item: district)
    end
  end
end
