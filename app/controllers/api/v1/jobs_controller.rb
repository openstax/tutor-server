module Api
  module V1
    class JobsController < ApiController
      def show
        status = Resque::Plugins::Status::Hash.get(params[:id])
        render json: { status: status }
      end
    end
  end
end
