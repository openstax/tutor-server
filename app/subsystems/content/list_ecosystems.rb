class Content::ListEcosystems
  lev_routine express_output: :ecosystems

  protected

  def exec
    ecosystems = Content::Ecosystem.all
    outputs[:ecosystems] = ecosystems.collect do |ecosystem|
      Hashie::Mash.new(
        id: ecosystem.id,
        title: ecosystem.title,
        books: ecosystem.books.collect do |book|
          Hashie::Mash.new(
            title: book.title,
            url: book.url,
            uuid: book.uuid,
            version: book.version
          )
        end
      )
    end
  end
end
