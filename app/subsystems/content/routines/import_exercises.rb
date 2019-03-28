class Content::Routines::ImportExercises
  lev_routine

  uses_routine Content::Routines::FindOrCreateTags,
               as: :find_or_create_tags,
               translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  protected

  # page can be a Content::Models::Page or a block
  # that takes an OpenStax::Exercises::V1::Exercise
  # and returns a Content::Models::Page for that exercise
  def exec(ecosystem:, page:, query_hash:, collaborators: [ 'openstax' ])
    # Query the exercises to get a list of OpenStax::Exercises::V1::Exercise
    query_hash = query_hash.merge collaborator: collaborators.join(',')
    Rails.logger.warn query_hash
    OpenStax::Exercises::V1.exercises(query_hash) do |wrappers|
    debugger
      # Go through the wrappers and build a map of wrappers to pages
      wrapper_to_exercise_page_map = {}
      wrappers.each do |wrapper|
        exercise_page = page.respond_to?(:call) ? page.call(wrapper) : page

        # Skip exercises that don't belong to any of the available pages
        # This could happen, for example, if a manifest for a different environment is imported
        next if exercise_page.nil?

        # Skip exercises that have any free response questions, as we can't handle them.
        # Could use `free-response` format, but let's cut to chase and look for no M/C answers.
        next if wrapper.content_hash["questions"].any? { |qq| qq["answers"].empty? }

        # Assign exercise context if required
        if wrapper.requires_context?
          feature_ids = wrapper.feature_ids(exercise_page.uuid)
          wrapper.context = exercise_page.context_for_feature_ids(feature_ids)

          if wrapper.context.blank?
            if feature_ids.empty?
              Rails.logger.warn do
                "Exercise #{wrapper.uid} requires context but it has no feature ID tags"
              end
            else
              Rails.logger.warn do
                "Exercise #{wrapper.uid} requires context but its feature ID(s) [ #{
                  feature_ids.join(', ')} ] could not be found on #{exercise_page.url}"
              end
            end
          end
        end

        wrapper_to_exercise_page_map[wrapper] = exercise_page
      end

      # Pre-build all tags we are going to need in one shot
      wrapper_tag_hashes = wrappers.flat_map(&:tag_hashes).uniq { |hash| hash[:value] }
      run(:find_or_create_tags, ecosystem: ecosystem, input: wrapper_tag_hashes)
      tag_map = outputs.tags.index_by(&:value)

      exercises = wrapper_to_exercise_page_map.map do |wrapper, exercise_page|
        exercise = Content::Models::Exercise.new(page: exercise_page,
                                                 url: wrapper.url,
                                                 uuid: wrapper.uuid,
                                                 group_uuid: wrapper.group_uuid,
                                                 number: wrapper.number,
                                                 version: wrapper.version,
                                                 nickname: wrapper.nickname,
                                                 title: wrapper.title,
                                                 preview: wrapper.preview,
                                                 context: wrapper.context,
                                                 content: wrapper.content,
                                                 has_interactive: wrapper.has_interactive?,
                                                 has_video: wrapper.has_video?)

        relevant_tags = wrapper.tags.map { |tag| tag_map[tag] }.compact
        run(:tag, exercise, relevant_tags, tagging_class: Content::Models::ExerciseTag, save: false)

        # Clear the outputs to avoid memory bloat (by not keeping all the tags in memory)
        @result = Lev::Routine::Result.new(Lev::Outputs.new, errors)

        exercise
      end

      Content::Models::Exercise.import exercises, recursive: true, validate: false

      # Reset associations so they get reloaded the next time they are used
      page.exercises.reset if page.is_a?(Content::Models::Page)

      exercise_pages = wrapper_to_exercise_page_map.values.compact.uniq
      exercise_pages.each{ |page| page.exercises.reset }
    end
  end
end
