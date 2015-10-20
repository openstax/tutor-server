module OpenStax
  module Cnx
    module V1
    end
  end
end

%w(
  v1/fragment_splitter
  v1/fragment/acts_as_fragment
  v1/fragment/embedded
  v1/fragment/exercise
  v1/fragment/exercise_choice
  v1/fragment/feature
  v1/fragment/interactive
  v1/fragment/text
  v1/fragment/video
  v1/book
  v1/book_part
  v1/page
  v1/book_visitor
  v1/book_to_string_visitor
  v1
).each do |f|
  require_relative "./#{f}"
end
