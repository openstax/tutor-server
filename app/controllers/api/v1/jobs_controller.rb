module Api
  module V1
    class JobsController < ApiController
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
        else
          202
        end
      end
    end
  end
end
