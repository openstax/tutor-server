class Admin::EcosystemsController < Admin::BaseController
  include Manager::EcosystemsActions

  protected

  def ecosystems_path
    admin_ecosystems_path
  end
end
