class Content::Routines::ImportExercises
  lev_routine

  uses_routine Content::Routines::TagResource, as: :tag

  protected

  # page can be a Content::Models::Page or a block
  # that takes an OpenStax::Exercises::V1::Exercise
  # and returns a Content::Models::Page for that exercise
  def exec(ecosystem:, page:, query_hash:, collaborators: [], all_tags: nil)
    # Query the exercises to get a list of OpenStax::Exercises::V1::Exercise
    if collaborators.any?
      query_hash = query_hash.merge collaborator: collaborators.join(',')
    end

    OpenStax::Exercises::V1.exercises(query_hash) do |wrappers|
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

      exercises = wrapper_to_exercise_page_map.map do |wrapper, exercise_page|
        exercise = Content::Models::Exercise.new(
          page: exercise_page,
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
          number_of_questions: wrapper.questions.size,
          question_answer_ids: wrapper.question_answer_ids,
          has_interactive: wrapper.has_interactive?,
          has_video: wrapper.has_video?
        )

        all_tags = run(
          :tag,
          ecosystem: ecosystem,
          resource: exercise,
          tags: wrapper.tag_hashes,
          tagging_class: Content::Models::ExerciseTag,
          save_tags: false,
          all_tags: all_tags
        ).outputs.all_tags

        exercise
      end

      changed_tags = (all_tags || []).filter(&:changed?)
      Content::Models::Tag.import changed_tags, validate: false, on_duplicate_key_update: {
        conflict_target: [ :value, :content_ecosystem_id ],
        columns: [ :name, :description, :tag_type ]
      } unless changed_tags.empty?

      exercises.each_slice(15) do |exs|
        Content::Models::Exercise.import exs, recursive: true, validate: false
      end

      # Reset associations so they get reloaded the next time they are used
      page.exercises.reset if page.is_a?(Content::Models::Page)

      exercise_pages = wrapper_to_exercise_page_map.values.compact.uniq
      exercise_pages.each { |page| page.exercises.reset }
    end
  end
end
