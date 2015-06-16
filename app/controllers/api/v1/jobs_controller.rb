module Api
  module V1
    class JobsController < ApiController
      def show
        render json: Lev::Status.find(params[:id])
      end
    end
  end
end
