class Admin::BooksController < Admin::BaseController
  def index
    @books = Content::ListBooks[]
  end

  def import
    @default_archive_url = OpenStax::Cnx::V1.archive_url_base
    import_book if request.post?
  end

  protected
  def import_book
    archive_url = params[:archive_url].present? ? params[:archive_url] : @default_archive_url

    # Check whether book exists
    book = get_book(archive_url, params[:cnx_id])
    unless book.nil?
      flash[:error] = "Book \"#{book.title}\" already imported."
      return render :import
    end

    OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      cnx_book = FetchAndImportBook.call(id: params[:cnx_id]).outputs.cnx_book
      flash[:notice] = "Book \"#{cnx_book.title}\" imported."
    end
    redirect_to admin_books_path
  end

  def get_book(archive_url, cnx_id)
    OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      url = OpenStax::Cnx::V1.url_for(cnx_id)
      Content::Models::BookPart.roots.where(url: url).first
    end
  end
end
