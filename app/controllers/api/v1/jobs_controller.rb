class Api::V1::JobsController < Api::V1::ApiController
  resource_description do
    api_versions "v1"
    short_description 'Represents queued jobs in the system'
    description <<-EOS
      ActiveJob jobs description to be written...
    EOS
  end

  api :GET, '/jobs/:id', 'Returns job statuses'
  description <<-EOS
    Returns queued job statuses in the system
    { status: \\[:queued, :working, :completed, :failed, :killed\\] }
  EOS
  def show
    status = Lev::Status.find(params[:id])
    code = http_status_code(status['state'])
    render json: status, status: code
  end

  private
  def http_status_code(switch)
    case switch
    when Lev::Status::STATE_COMPLETED
      200
    when Lev::Status::STATE_FAILED
      500
    when Lev::Status::STATE_KILLED
      404
    else
      202
    end
  end
end
