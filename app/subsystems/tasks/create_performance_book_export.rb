module Tasks
  class CreatePerformanceBookExport
    lev_routine

    def exec(course:, role:, filepath:)
      export = Models::PerformanceBookExport.new(course: course, role: role)
      File.open(filepath) { |f| export.file = f }
      export.save!
    end
  end
end
