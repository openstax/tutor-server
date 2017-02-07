class Content::Routines::ImportExercises

  lev_routine

  uses_routine Content::Routines::FindOrCreateTags, as: :find_or_create_tags
  uses_routine Content::Routines::TagResource, as: :tag

  protected

  # TODO: make this routine import only exercises from trusted authors
  #       or in some trusted list (for when OS Exercises is public)
  # page can be a Content::Models::Page or a block
  # that takes an OpenStax::Exercises::V1::Exercise
  # and returns a Content::Models::Page for that exercise
  def exec(ecosystem:, page:, query_hash:, excluded_exercise_numbers: [])
    outputs[:exercises] = []

    # Query the exercises to get a list of OpenStax::Exercises::V1::Exercise and
    # wrap them in a local mutable form of that class

    wrappers = OpenStax::Exercises::V1.exercises(query_hash).map{ |item| MutableWrapper.new(item) }

    # Go through wrappers and build a map of wrappers to pages

    wrapper_to_exercise_page_map = {}

    wrappers.each do |wrapper|
      # Skip excluded_exercise_numbers (duplicates)
      # Necessary because we split queries to Exercises into smaller queries to avoid timeouts

      next if excluded_exercise_numbers.include?(wrapper.number)

      exercise_page = page.respond_to?(:call) ? page.call(wrapper) : page

      # Skip exercises that don't belong to any of the available pages
      # This could happen, for example, if a manifest for a different environment is imported

      next if exercise_page.nil?

      # Skip exercises that have any free response questions, as we can't handle them.
      # Could use `free-response` format, but let's cut to chase and look for no M/C answers.

      next if wrapper.content_hash["questions"].any?{ |qq| qq["answers"].empty? }

      # Add `lo:page_uuid` style tags for wrappers missing other LOs

      wrapper.add_lo("lo:#{exercise_page.uuid}") if wrapper.los.none? && wrapper.aplos.none?

      # Assign exercise context if required

      if wrapper.requires_context?
        feature_ids = wrapper.feature_ids(exercise_page.uuid)
        wrapper.context = exercise_page.context_for_feature_ids(feature_ids)

        Rails.logger.warn do
          "Exercise #{wrapper.uid} requires context, but feature ID(s) [#{
            feature_ids.join(', ')}] could not be found on #{exercise_page.url}"
        end if wrapper.context.blank?
      end

      wrapper_to_exercise_page_map[wrapper] = exercise_page
    end

    # Pre-build all tags we are going to need in one shot

    wrapper_tag_hashes = wrappers.flat_map(&:tag_hashes).uniq{ |hash| hash[:value] }
    tags = run(:find_or_create_tags, ecosystem: ecosystem, input: wrapper_tag_hashes).outputs.tags
    tag_map = tags.index_by(&:value)

    wrapper_to_exercise_page_map.each do |wrapper, exercise_page|
      exercise = Content::Models::Exercise.new(page: exercise_page,
                                               url: wrapper.url,
                                               uuid: wrapper.uuid,
                                               group_uuid: wrapper.group_uuid,
                                               number: wrapper.number,
                                               version: wrapper.version,
                                               title: wrapper.title,
                                               preview: wrapper.preview,
                                               context: wrapper.context,
                                               content: wrapper.content,
                                               has_interactive: wrapper.has_interactive?,
                                               has_video: wrapper.has_video?)

      relevant_tags = wrapper.tags.map{ |tag| tag_map[tag] }.compact
      run(:tag, exercise, relevant_tags, tagging_class: Content::Models::ExerciseTag, save: false)

      outputs[:exercises] << exercise
    end

    Content::Models::Exercise.import outputs[:exercises], recursive: true, validate: false

    # Reset associations so they get reloaded the next time they are used
    page.exercises.reset if page.is_a?(Content::Models::Page)

    exercise_pages = wrapper_to_exercise_page_map.values.compact.uniq
    exercise_pages.each{ |page| page.exercises.reset }
  end

  # Instead of modifying OpenStax::Exercises::V1::Exercise to become immutable,
  # this delegator gives us the mutable extension to that class that we need
  # just while importing exercises

  class MutableWrapper < SimpleDelegator
    # Adds an LO tag, this impacts many tag methods but notably we don't
    # make an attempt to alter the underlying content hash.
    def add_lo(lo)
      extra_los.push(lo)
      extra_lo_hashes.push({value: lo, name: nil, type: :lo})
    end

    def extra_los
      @extra_los ||= []
    end

    def extra_lo_hashes
      @extra_lo_hashes ||= []
    end

    def tags;               __getobj__.tags              + extra_los;       end
    def los;                __getobj__.los               + extra_los;       end
    def import_tags;        __getobj__.import_tags       + extra_los;       end
    def tag_hashes;         __getobj__.tag_hashes        + extra_lo_hashes; end
    def lo_hashes;          __getobj__.lo_hashes         + extra_lo_hashes; end
    def import_tag_hashes;  __getobj__.import_tag_hashes + extra_lo_hashes; end
  end

end
