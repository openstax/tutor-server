class CustomerService::EcosystemsController < CustomerService::BaseController
  def index
    @ecosystems = Content::ListEcosystems[]
  end
end
