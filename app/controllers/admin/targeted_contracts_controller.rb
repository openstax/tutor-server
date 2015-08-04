class Admin::TargetedContractsController < Admin::BaseController

  def index
    @contracts = Legal::GetTargetedContracts[]
  end

  def show
    @contract = Legal::GetTargetedContracts[ids: params[:id]]
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

  def new
    @targets = SchoolDistrict::ListDistricts[].collect do |district|
      Hashie::Mash.new(value: "#{district.gid}|#{district.name}", name: district.name)
    end
  end

end
