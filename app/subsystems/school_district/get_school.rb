module SchoolDistrict
  class GetSchool
    lev_routine outputs: { school: :_self }

    protected
    def exec(id: nil, name: nil)
      if !id.blank? && id != 0 # webforms weirdness
        set(school: Models::School.find(id))
      elsif !name.blank?
        set(school: Models::School.where(name: name).first)
      end
    end
  end
end
