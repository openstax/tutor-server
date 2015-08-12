class Content::ListEcosystems
  lev_routine express_output: :ecosystems

  protected

  def exec
    ecosystems = Content::Ecosystem.all.sort_by{ |es| es.books.first.title.downcase }
    outputs[:ecosystems] = ecosystems.collect do |ecosystem|
      Hashie::Mash.new(
        id: ecosystem.id,
        books: ecosystem.books.collect do |book|
          Hashie::Mash.new(
            title: book.title,
            url: book.url,
            uuid: book.uuid,
            version: book.version,
            title_with_id: "#{book.title} (#{book.uuid}@#{book.version})"
          )
        end
      )
    end
  end
end
