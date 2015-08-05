module SchoolDistrict
  class DeleteDistrict
    lev_routine

    protected
    def exec(id:)
      district = Models::District.find(id)
      district.destroy
      transfer_errors_from(district, {type: :verbatim}, true)

      # TODO find a better home for this
      Legal::ForgetAbout[item: district]
    end
  end
end
