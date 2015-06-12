module Api
  module V1
    class JobsController < ApiController
      def show
        status = ActiveJobStatus::JobStatus.get_status(job_id: params[:id])
        render json: { status: status || :completed }
      end
    end
  end
end
