require_relative '../fragment'

class OpenStax::Content::Fragment::Reading < OpenStax::Content::Fragment::Html
  def initialize(node:, title: nil, labels: nil, reference_view_url: nil)
    super node: node, title: title, labels: labels

    @reference_view_url = reference_view_url
  end
end
