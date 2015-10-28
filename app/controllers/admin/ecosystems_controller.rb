class Admin::EcosystemsController < Admin::BaseController
  include Manager::EcosystemsActions

  def ecosystems_path
    admin_ecosystems_path
  end
end
