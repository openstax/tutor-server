module CourseDetail
  class DeleteDistrict
    lev_routine

    protected
    def exec(id:)
      Models::District.find(id).destroy
    end
  end
end
