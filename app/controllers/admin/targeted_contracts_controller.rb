class Admin::TargetedContractsController < Admin::BaseController

  before_filter :load_district_targets, only: [:new]

  def index
    @contracts = Legal::GetTargetedContracts[]
  end

  def create
    handle_with(Admin::TargetedContractsCreate,
                complete: -> {
                  redirect_to admin_targeted_contracts_path,
                              notice: 'The targeted contract has been created.'
                })
  end

  def destroy
    Legal::DestroyTargetedContract[id: params[:id]]
    redirect_to admin_targeted_contracts_path
  end

  protected

  def load_district_targets
    @targets = SchoolDistrict::ListDistricts[].map do |district|
      Hashie::Mash.new(value: "#{district.to_global_id}|#{district.name}", name: district.name)
    end
  end

end
