class AddConceptCoachPoolToContentPages < ActiveRecord::Migration
  def change
    add_column :content_pages, :content_concept_coach_pool_id, :integer

    reversible do |dir|
      dir.up do
        page_cc_exercises = Content::Models::Exercise
                              .joins(exercise_tags: :tag)
                              .where(exercise_tags: {tag: {value: 'ost-type:concept-coach'}})
                              .group_by(&:content_page_id)

        all_cc_exercises = page_cc_exercises.values.flatten.uniq

        biglearn_exercises_by_ids = {}
        all_cc_exercises.each do |ex|
          exercise_url = Addressable::URI.parse(ex.url)
          exercise_url.scheme = nil
          exercise_url.path = exercise_url.path.split('@').first

          biglearn_exercises_by_ids[ex.id] = OpenStax::Biglearn::V1::Exercise.new(
            # The Biglearn add pools API does not use the exercise tags
            question_id: exercise_url.to_s, version: ex.version, tags: []
          )
        end

        all_sorted_page_ids = Content::Models::Page.order(:id).pluck(:id)

        biglearn_pools = all_sorted_page_ids.map do |page_id|
          cc_exercises = page_cc_exercises[page_id] || []
          cc_exercise_ids = cc_exercises.map(&:id)
          biglearn_exercises = cc_exercise_ids.map{ |id| biglearn_exercises_by_ids[id] }
          OpenStax::Biglearn::V1::Pool.new(exercises: biglearn_exercises)
        end

        # Send pools to Biglearn
        biglearn_pools_with_uuids = OpenStax::Biglearn::V1.add_pools(biglearn_pools)

        page_cc_pool_uuids = {}
        all_sorted_page_ids.each_with_index do |page_id, index|
          page_cc_pool_uuids[page_id] = biglearn_pools_with_uuids[index].uuid
        end

        cc_pools = Content::Models::Page.preload(:ecosystem).find_each.map do |page|
          cc_exercises = page_cc_exercises[page.id] || []
          Content::Models::Pool.create!(
            ecosystem: page.ecosystem,
            pool_type: :concept_coach,
            content_exercise_ids: cc_exercises.map(&:id),
            uuid: page_cc_pool_uuids[page.id]
          ).tap do |cc_pool|
            page.update_attribute :concept_coach_pool, cc_pool
          end
        end
      end

      dir.down{ Content::Models::Pool.where(pool_type: :concept_coach).delete_all }
    end
  end
end
