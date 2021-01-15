class BuildTeacherExerciseContentHash
  lev_routine express_output: :content_hash, transaction: :no_transaction

  TIMES = { tag: 'time', key: :tagTime, values: ['short', 'medium', 'long'] }
  DIFFICULTIES = { tag: 'difficulty', key: :tagDifficulty, values: ['easy', 'medium', 'difficult'] }
  BLOOMS = { tag: 'blooms', key: :tagBloom, values: ['1', '2', '3', '4', '5', '6'] }
  DOKS = { tag: 'dok', key: :tagDok, values: ['1', '2', '3', '4'] }

  protected

  def exec(data:)
    content_hash = {}

    content_hash[:tags] = [TIMES, DIFFICULTIES, BLOOMS, DOKS].map do |tag|
      value = (data[:tags] || {}).dig(tag[:key], :value)
      "#{tag[:tag]}:#{value}" if tag[:values].include? value
    end
    content_hash[:tags].compact!

    question = {
      id: SecureRandom.uuid,
      is_answer_order_important: true,
      stimulus_html: "",
      stem_html: sanitize(data[:questionText]),
      title: sanitize(data[:questionName]),
      collaborator_solutions: [],
      combo_choices: [],
      community_solutions: [],
      hints: []
    }

    question[:answers] = (data[:options] || []).map.with_index do |option, i|
      {
        id: SecureRandom.uuid,
        content_html: sanitize(option[:content]),
        correctness: sanitize(option[:correctness]),
        feedback_html: sanitize(option[:feedback])
      }
    end

    if data[:detailedSolution]
      question[:collaborator_solutions] << {
        attachments: [],
        solution_type: 'detailed',
        content_html: sanitize(data[:detailedSolution])
      }
    end

    question[:formats] = [].tap do |formats|
      formats << "free-response" if data[:isTwoStep] || question[:answers].empty?
      formats << "multiple-choice" if question[:answers].any?
    end

    content_hash[:questions] = [question]

    # Extraneous fields
    content_hash.merge!({
      stimulus_html: '',
      derived_from: [],
      is_vocab: false,
      authors: [],
      uuid: '',
      group_uuid: ''
    })

    if content_hash[:questions][0][:formats].any?('multiple-choice')
      unless content_hash[:questions][0][:answers].one? {|a| a[:correctness] == '1.0' }
        fatal_error(
          code: :multiple_choice_must_have_valid_correctness,
          message: 'Multiple choice must have 1 option with a correctness of 1.0'
        )
      end
    end

    outputs.content_hash = content_hash
  end

  def sanitize(html)
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
    @scrubber  ||= TeacherExerciseScrubber.new
    @sanitizer.sanitize(html.to_s, scrubber: @scrubber)
  end
end

class TeacherExerciseScrubber < Rails::Html::PermitScrubber
  ALLOWED_TAGS = %w(
    a
    img
    strong
    em
    span
    div
    table
    colgroup
    col
    tbody
    tr
    td
    p
    br
    iframe
    ol
    ul
    li
    blockquote
    sub
    sup
    hr
    math
    h1
    h2
    h3
    h4
  )
  ALLOWED_ATTRS = %w(
    alt title src width height style data-math type align
  )
  ALLOWED_IFRAME_ATTRS = %w(
    allowfullscreen class frameborder height mozallowfullscreen
    scrolling src width webkitallowfullscreen
  )

  EMBED_URL_REGEXES = [
    /\A(?:https?:)?\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//,
    /\A(?:https?:)?\/\/(?:www\.)?khanacademy\.org\//,
    /\A(?:https?:)?\/\/(?:[\w-]+\.)?cnx\.org\//,
    /\A(?:https?:)?\/\/(?:[\w-]+\.)?openstax\.org\//,
    /\A(?:https?:)?\/\/(?:[\w-]+\.)?openstaxcollege\.org\//,
    /\A(?:https?:)?\/\/phet\.colorado\.edu\//
  ]

  def initialize
    super
    self.tags = ALLOWED_TAGS
    self.attributes = ALLOWED_ATTRS
  end

  def keep_node?(node)
    if node.name == 'iframe'
      return false unless EMBED_URL_REGEXES.any? {|regex| node['src'] =~ regex }
    end

    super
  end

  def scrub_attribute?(node, name)
    if node.name == 'iframe'
      return true unless ALLOWED_IFRAME_ATTRS.include?(name)
    else
      super(name)
    end
  end

  def scrub_attributes(node)
    if @attributes
      node.attribute_nodes.each do |attr|
        attr.remove if scrub_attribute?(node, attr.name)
        scrub_attribute(node, attr)
      end

      scrub_css_attribute(node)
    else
      Loofah::HTML5::Scrub.scrub_attributes(node)
    end
  end
end
