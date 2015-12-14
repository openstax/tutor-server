class CustomerService::TagsController < CustomerService::BaseController
  def index
    @tags = Content::SearchTags.call(tag_value: "%#{params[:query]}%")
              .paginate(page: params[:page], per_page: 100) if params[:query].present?
  end
end
