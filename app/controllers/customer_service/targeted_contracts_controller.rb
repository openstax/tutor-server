class CustomerService::TargetedContractsController < CustomerService::BaseController
  def index
    @contracts = Legal::GetTargetedContracts[]
  end
end
