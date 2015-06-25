module CourseDetail
  class UpdateDistrict
    lev_routine express_output: :district

    protected
    def exec(id:, attributes: {}, caller:)
      district = GetDistrict[id: id, action: :update, caller: caller]

      district.update_attributes(attributes)

      outputs[:district] = {
        id: district.id,
        name: district.name
      }
    end
  end
end
