class Legal::GetTargetedContracts
  lev_routine express_output: :contracts

  protected

  def exec(ids: :all, applicable_to: nil)
    contracts = Legal::Models::TargetedContract.all

    unless applicable_to.nil?
      applicable_models = [ applicable_to ].flatten.flat_map do |model|
        case model
        when CourseProfile::Models::Course
          [ model, model.school, model.school.try!(:district) ].compact
        when SchoolDistrict::Models::School
          [ model, model.district ].compact
        when SchoolDistrict::Models::District
          [ model ]
        else
          []
        end
      end

      contracts = contracts.where(
        target_gid: applicable_models.map { |item| Legal::Utils.gid(item) }
      )
    end

    contracts = Legal::Models::TargetedContract.all
    contracts = contracts.where(id: [ids].flatten.compact) if ids != :all
    contracts = contracts.where(
      target_gid: applicable_models.map { |item| Legal::Utils.gid(item) }
    ) unless applicable_models.nil?

    outputs.contracts = contracts.map(&:as_poro)
  end
end
