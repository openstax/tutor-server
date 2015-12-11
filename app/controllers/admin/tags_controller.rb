class Admin::TagsController < Admin::BaseController
  before_action :get_tag, except: [:index]

  def index
    @tags = Content::SearchTags.call(tag_value: "%#{params[:query]}%")
              .paginate(page: params[:page], per_page: 100) if params[:query].present?
  end

  def edit
  end

  def update
    @tag.update_attributes(name: params[:tag][:name],
                           description: params[:tag][:description],
                           visible: params[:tag][:visible])
    flash[:notice] = 'The tag has been updated.'
    redirect_to admin_tags_path(value: @tag.value)
  end

  private

  def get_tag
    @tag = Content::Models::Tag.find(params[:id])
  end
end
