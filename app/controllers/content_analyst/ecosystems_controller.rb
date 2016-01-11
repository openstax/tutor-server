class ContentAnalyst::EcosystemsController < ContentAnalyst::BaseController
  include Manager::EcosystemsActions

  protected

  def ecosystems_path
    content_analyst_ecosystems_path
  end
end
