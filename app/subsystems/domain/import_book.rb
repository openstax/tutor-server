class Domain::ImportBook
  lev_routine

  uses_routine Content::Api::ImportBook,
               translations: {outputs: {type: :verbatim}}

  protected

  def exec(cnx_id:)
    run(Content::Api::ImportBook, cnx_id)
  end

end