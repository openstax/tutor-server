module Catalog
  class Offering

    include Wrapper

    wrap_attributes ::Catalog::Models::Offering,
       :id, :identifier, :is_tutor, :is_concept_coach, :description, :webview_url, :pdf_url

  end
end
