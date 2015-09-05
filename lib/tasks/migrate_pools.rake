desc 'Temporary rake task to be used to add the new all_exercises_pool to existing chapters and pages'
task :migrate_pools => [:environment, :'db:migrate'] do |tt, args|
  # Find pages and chapters without the all_exercises_pool and assign them
  # while also sending the new pools to Biglearn
  Content::Models::Chapter.transaction do
    Content::Models::Chapter.lock.where(content_all_exercises_pool_id: nil).flat_map do |chapter|
      ecosystem = chapter.ecosystem

      chapter.pages.to_a.select{ |page| page.all_exercises_pool.nil? }.flat_map do |page|
        base_page_pool = page.practice_widget_pool
        all_page_exercise_ids = base_page_pool.content_exercise_ids

        base_biglearn_page_pool = OpenStax::Biglearn::V1::Pool.new(uuid: base_page_pool.uuid)
        new_biglearn_page_pool = OpenStax::Biglearn::V1.combine_pools([base_biglearn_page_pool])

        page.all_exercises_pool = Content::Models::Pool.create!(
          ecosystem: ecosystem,
          pool_type: :all_exercises,
          content_exercise_ids: all_page_exercise_ids,
          uuid: new_biglearn_page_pool.uuid
        )
        page.save!
      end

      base_chapter_pools = chapter.pages.collect(&:all_exercises_pool)
      all_chapter_exercise_ids = base_chapter_pools.flat_map(&:content_exercise_ids).uniq

      base_biglearn_chapter_pools = base_chapter_pools.collect do |pool|
        OpenStax::Biglearn::V1::Pool.new(uuid: pool.uuid)
      end
      new_biglearn_chapter_pool = OpenStax::Biglearn::V1.combine_pools(base_biglearn_chapter_pools)

      chapter.all_exercises_pool = Content::Models::Pool.create!(
        ecosystem: ecosystem,
        pool_type: :all_exercises,
        content_exercise_ids: all_chapter_exercise_ids,
        uuid: new_biglearn_chapter_pool.uuid
      )
      chapter.save!
    end
  end
end
