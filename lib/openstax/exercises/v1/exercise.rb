class OpenStax::Exercises::V1::Exercise

  VIDEO_CSS = 'iframe[src*="youtube"], iframe[src*="khanacademy"]'
  INTERACTIVE_CSS = 'iframe:not([src*="youtube"]):not([src*="khanacademy"])'

  # Context must be externally set before the preview initialized
  attr_accessor :context
  attr_reader :content

  def initialize(content: '{}', server_url: OpenStax::Exercises::V1.server_url)
    @content = content
    @server_url = server_url
  end

  def content_hash
    return @content_hash unless @content_hash.nil?

    @content_hash = JSON.parse(content)
    stringify_content_hash_ids!
    @content_hash
  end

  def uuid
    @uuid ||= content_hash['uuid']
  end

  def group_uuid
    @uuid ||= content_hash['group_uuid']
  end

  def number
    @number ||= content_hash['number']
  end

  def version
    @version ||= content_hash['version']
  end

  def uid
    @uid ||= content_hash['uid']
  end

  def url
    @url ||= "#{@server_url}/exercises/#{uid}"
  end

  def title
    @title ||= content_hash['title']
  end

  def tags
    @tags ||= content_hash['tags']
  end

  def tag_hashes
    @tag_hashes ||= tags.map{ |tag| Tagger.get_hash(tag) }
  end

  def lo_hashes
    @lo_hashes ||= tag_hashes.select{ |hash| hash[:type] == :lo }
  end

  def aplo_hashes
    @aplo_hashes ||= tag_hashes.select{ |hash| hash[:type] == :aplo }
  end

  def cnxmod_hashes
    @cnxmod_hashes ||= tag_hashes.select{ |hash| hash[:type] == :cnxmod }
  end

  def cnxfeature_hashes
    @cnxfeature_hashes ||= tag_hashes.select{ |hash| hash[:type] == :cnxfeature }
  end

  def import_tag_hashes
    @import_tag_hashes ||= lo_hashes + aplo_hashes + cnxmod_hashes
  end

  def los
    @los ||= lo_hashes.map{ |hash| hash[:value] }
  end

  def aplos
    @aplos ||= aplo_hashes.map{ |hash| hash[:value] }
  end

  def cnxmods
    @cnxmods ||= cnxmod_hashes.map{ |hash| hash[:value] }
  end

  def cnxfeatures
    @cnxfeatures ||= cnxfeature_hashes.map{ |hash| hash[:value] }
  end

  def import_tags
    @import_tags ||= import_tag_hashes.map{ |hash| hash[:value] }
  end

  def feature_ids(page_uuid)
    feature_tag_start = 'context-cnxfeature:'
    feature_tags = cnxfeatures.select{ |tag| tag.start_with? feature_tag_start }
    feature_tags.map{ |tag| tag.sub(feature_tag_start, '') }
  end

  def questions
    @questions ||= content_hash['questions']
  end

  def question_formats
    @question_formats ||= questions.map{ |qq| qq['formats'] }
  end

  def question_answers
    @question_answers ||= questions.map{ |qq| qq['answers'] }
  end

  def question_answer_ids
    @question_answer_ids ||= question_answers.map do |qa|
      qa.map{ |ans| ans['id'] }
    end
  end

  def correct_question_answers
    @correct_question_answers ||= question_answers.map do |qa|
      qa.select do |ans|
        (Float(ans['correctness']) rescue 0) >= 1
      end
    end
  end

  def correct_question_answer_ids
    @correct_question_answer_ids ||= correct_question_answers.map do |cqa|
      cqa.map{ |ans| ans['id'].to_s }
    end
  end

  def solutions
    @solutions ||= questions.map{ |qq| qq['solutions'] }
  end

  def feedback_map
    return @feedback_map unless @feedback_map.nil?

    @feedback_map = {}
    question_answers.each do |qa|
      qa.each { |ans| @feedback_map[ans['id']] = ans['feedback_html'] }
    end
    @feedback_map
  end

  def question_answers_without_correct_answer
    @question_answers_without_correct ||= question_answers.map do |qa|
      qa.map{ |ans| ans.except('correctness', 'feedback_html') }
    end
  end

  def questions_without_correct_answer
    @questions_without_correct ||= questions.each_with_index.map do |qq, ii|
      qq.except('collaborator_solutions', 'community_solutions')
        .merge('answers' => question_answers_without_correct_answer[ii])
    end
  end

  def content_hash_for_students
    @content_hash_for_students ||= content_hash.except('attachments', 'vocab_term_uid').merge(
      'questions' => questions_without_correct_answer
    )
  end

  def preview
    initialize_preview
    @preview
  end

  def is_multipart?
    questions.size > 1
  end

  def has_interactive?
    initialize_preview
    @has_interactive
  end

  def has_video?
    initialize_preview
    @has_video
  end

  def requires_context?
    return @requires_context unless @requires_context.nil?

    @requires_context = tags.any?{ |tag| Tagger::TAG_TYPE_REGEXES[:requires_context].match(tag) }
  end

  protected

  def stringify_content_hash_ids!
    (@content_hash['authors'] || []).each do |au|
      au['user_id'] = au['user_id'].try(:to_s)
    end

    (@content_hash['copyright_holders'] || []).each do |cr|
      cr['user_id'] = cr['user_id'].try(:to_s)
    end

    (@content_hash['questions'] || []).each do |qq|
      qq['id'] = qq['id'].try(:to_s)
      (qq['answers'] || []).each do |aa|
        aa['id'] = aa['id'].try(:to_s)
      end
    end
  end

  def preview_root
    @preview_root ||= Nokogiri::HTML.fragment(
      (
        [context, content_hash['stimulus_html']] + questions.flat_map do |question_hash|
          [question_hash['stimulus_html'], question_hash['stem_html']]
        end
      ).join("\n")
    )
  end

  def initialize_preview
    return if @preview_initialized

    interactive_nodes = preview_root.css(INTERACTIVE_CSS)
    video_nodes = preview_root.css(VIDEO_CSS)

    @has_interactive = interactive_nodes.any?
    @has_video = video_nodes.any?
    @preview_initialized = true

    return unless @has_interactive || @has_video

    interactive_nodes.each do |node|
      node.replace('<div class="preview interactive">Interactive</div>')
    end
    video_nodes.each{ |node| node.replace('<div class="preview video">Video</div>') }

    @preview = preview_root.to_html
  end

end
