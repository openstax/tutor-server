class CustomerService::TagsController < CustomerService::BaseController
  def index
    @tags = Content::SearchTags[tag_value: "%#{params[:value]}%"].paginate(page: params[:page], per_page: 100) if params[:value].present?
  end
end
