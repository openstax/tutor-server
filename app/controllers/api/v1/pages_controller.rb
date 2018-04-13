class Api::V1::PagesController < Api::V1::ApiController

  api :GET, '/pages/:uuid(@:version)', 'Return content html of the page'
  description <<-EOS
    #{json_schema(Api::V1::PageRepresenter, include: :readable)}
  EOS
  def get_page
    params_uuid = params[:uuid]
    params_version = params[:version]

    query = Content::Models::Page.where { uuid == params_uuid }.order(version: :desc, id: :desc)
    query = query.where { version == params_version } if params_version.present?
    page = query.first

    page.nil? ?
      head(:not_found) :
      respond_with(page, represent_with: Api::V1::PageRepresenter)
  end
end
