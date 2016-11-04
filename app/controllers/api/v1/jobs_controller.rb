class Api::V1::JobsController < Api::V1::ApiController
  resource_description do
    api_versions "v1"
    short_description 'Represents queued jobs in the system'
    description <<-EOS
      ActiveJob jobs description to be written...
    EOS
  end

  api :GET, '/jobs', 'Returns all background jobs'
  description <<-EOS
    Returns queued jobs in the system
    #{json_schema(Api::V1::JobsRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, Jobba::Status)
    jobs = Jobba.all.to_a
    respond_with jobs, represent_with: Api::V1::JobsRepresenter
  end

  api :GET, '/jobs/:id', 'Returns job statuses'
  description <<-EOS
    Returns queued job statuses in the system
    #{json_schema(Api::V1::JobRepresenter, include: :readable)}
  EOS
  def show
    job = Jobba.find(params[:id])
    return render_api_errors(:job_not_found, :not_found) if job.nil?
    OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, job)
    respond_with job, represent_with: Api::V1::JobRepresenter
  end
end
