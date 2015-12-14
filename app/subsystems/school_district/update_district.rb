module SchoolDistrict
  class UpdateDistrict
    lev_routine outputs: { district: :_self }

    protected
    def exec(id:, attributes: {})
      district = Models::District.find(id)

      district.update_attributes(attributes)

      set(district: { id: district.id, name: district.name })
    end
  end
end
