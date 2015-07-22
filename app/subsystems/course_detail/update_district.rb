module CourseDetail
  class UpdateDistrict
    lev_routine express_output: :district

    protected
    def exec(id:, attributes: {})
      district = Models::District.find(id)

      district.update_attributes(attributes)

      outputs.district = {
        id: district.id,
        name: district.name
      }
    end
  end
end
