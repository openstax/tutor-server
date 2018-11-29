class Api::V1::PagesController < Api::V1::ApiController

  api :GET, '/ecosystems/:ecosystem_id/pages/:uuid(@:version)', 'Returns the content html of a page'
  description <<-EOS
    Returns the content html of a page

    #{json_schema(Api::V1::PageRepresenter, include: :readable)}
  EOS
  def show
    uuid, version = params[:id].split('@', 2)

    pages = Content::Models::Page.joins(chapter: :book).where(
      uuid: uuid, chapter: { book: { content_ecosystem_id: params[:ecosystem_id] } }
    )
    pages = pages.where(version: version) unless version.nil?
    page = pages.order(version: :desc, id: :desc).first

    page.nil? ? head(:not_found) : respond_with(page, represent_with: Api::V1::PageRepresenter)
  end
end
