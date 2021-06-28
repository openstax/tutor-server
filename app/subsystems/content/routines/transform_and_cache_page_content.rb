# This routine handles transforms that require a saved page, such as links containing the page id
# The page content changes, fragments and snap labs are then cached
class Content::Routines::TransformAndCachePageContent
  # Extract the uuid and version from paths like:
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@3
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@3#figure-1
  #   /contents/031da8d3-b525-429c-80cf-6c8ed997733a@9.98:127f63f7-d67f-4710-8625-2b1d4128ef6b@3
  OPENSTAX_ID_REGEX_STRING = <<-LINK_REGEX.strip_heredoc.gsub(/[\s\t]*/, '')
    /contents/
    (?:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:@([\\d\\.]+))?:)?
    ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:@([\\d\\.]+))?
  LINK_REGEX
  OPENSTAX_ID_REGEX = Regexp.new(OPENSTAX_ID_REGEX_STRING, Regexp::IGNORECASE)

  lev_routine

  protected

  def exec(book:, pages: nil, save: true)
    pages ||= book.pages.to_a

    # Get all page uuids and ox_ids given
    pages_by_uuid = pages.index_by(&:uuid)

    pages.each do |page|
      page.resolve_links!
      page.cache_fragments_and_snap_labs
    end

    # Get all exercises that require context
    ActiveRecord::Associations::Preloader.new.preload(pages, exercises: :tags)
    context_exercises = pages.flat_map { |page| page.exercises.filter(&:has_context?) }
    context_exercises_by_page_id = context_exercises.group_by(&:content_page_id)

    # Assign exercise context if required
    lookahead_exercises = []
    pages.each do |page|
      previous_context_exercises = lookahead_exercises
      lookahead_exercises = []
      (
        (context_exercises_by_page_id[page.id] || []) + previous_context_exercises
      ).each do |context_exercise|
        feature_ids = context_exercise.feature_ids
        context_exercise.context = page.context_for_feature_ids feature_ids
        next unless context_exercise.context.blank?

        if feature_ids.empty?
          Rails.logger.warn do
            "Exercise #{context_exercise.uid} requires context but it has no feature ID tags"
          end
        else
          lookahead_exercises << context_exercise
        end
      end
    end

    lookahead_exercises.each do |context_exercise|
      Rails.logger.warn do
        "Exercise #{context_exercise.uid} requires context but its feature ID(s) [ #{
          context_exercise.feature_ids.join(', ')
        } ] could not be found on its page or any subsequent pages"
      end
    end

    outputs.pages = pages

    return unless save

    # Pages are large enough that saving them individually seems faster than importing
    pages.each(&:save!)

    return if context_exercises.empty?

    Content::Models::Exercise.import context_exercises, validate: false, on_duplicate_key_update: {
      conflict_target: [ :id ], columns: [ :context ]
    }
  end
end
