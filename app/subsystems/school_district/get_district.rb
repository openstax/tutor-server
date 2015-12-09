module SchoolDistrict
  class GetDistrict
    lev_routine outputs: { district: :_self }

    protected
    def exec(id:)
      if !id.blank? && id != 0 # webforms weirdness
        set(district: Models::District.find(id))
      end
    end
  end
end
