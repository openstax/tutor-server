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
    job = Lev::BackgroundJob.find(params[:id])
    code = http_status_code(job.status)
    render json: job, with: :url, status: code
  end

  private
  def http_status_code(status)
    case status
    when Lev::BackgroundJob::STATE_COMPLETED
      200
    when Lev::BackgroundJob::STATE_FAILED
      500
    when Lev::BackgroundJob::STATE_KILLED || Lev::BackgroundJob::STATE_UNKNOWN
      404
    else
      202
    end
  end
end
