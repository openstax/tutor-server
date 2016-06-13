module Content
  module Strategies
    module Generated
      class Map

        class << self
          def create(from_ecosystems:, to_ecosystem:)
            strategy = new(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
            ::Content::Map.new(strategy: strategy)
          end

          def create!(from_ecosystems:, to_ecosystem:)
            create(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem).tap do |map|
              raise(
                Content::MapInvalidError, "Cannot generate a valid ecosystem map from " +
                "[#{from_ecosystems.map(&:title).join(', ')}] to #{to_ecosystem.title} " +
                "diagnostic=(#{map.validity_diagnostic_message})"
              ) unless map.valid?
            end
          end

          alias_method :find, :create

          alias_method :find!, :create!
        end

        def initialize(from_ecosystems:, to_ecosystem:)
          @from_ecosystems = from_ecosystems
          @to_ecosystem = to_ecosystem

          maps = merge_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)

          @page_id_to_pages_map = maps[:page_id_to_pages_map]
          @exercise_id_to_page_map = maps[:exercise_id_to_page_map]
          @pool_type_page_id_to_exercises_map = maps[:pool_type_page_id_to_exercises_map]
        end


        def merge_maps(from_ecosystems:, to_ecosystem:)
          existing = Content::Models::Map.where(content_from_ecosystem_id: from_ecosystems.map(&:id), content_to_ecosystem_id: to_ecosystem.id)

          existing_from_ecosystems_ids = existing.map(&:content_from_ecosystem_id)

          missing_from_ecosystems = from_ecosystems.reject do |ecosystem|
            existing_from_ecosystems_ids.include?(ecosystem.id)
          end

          new_maps = map_ecosystems(from_ecosystems: missing_from_ecosystems, to_ecosystem: to_ecosystem)

          page_id_to_pages_map = existing.map(&:page_id_to_pages_map).push(new_maps[:page_id_to_pages_map]).reduce(&:merge)
          exercise_id_to_page_map = existing.map(&:exercise_id_to_page_map).push(new_maps[:exercise_id_to_page_map]).reduce(&:merge)
          pool_type_page_id_to_exercises_map = existing.map(&:pool_type_page_id_to_exercises_map).push(new_maps[:pool_type_page_id_to_exercises_map]).reduce(&:merge)
          is_valid = existing.map(&:is_valid).push(new_maps[:is_valid]).all?
          # need to join
          validity_message = new_maps[:validity_message]

          cache_validity(is_valid, validity_message)

          map = {
            :page_id_to_pages_map => page_id_to_pages_map,
            :exercise_id_to_page_map => exercise_id_to_page_map,
            :pool_type_page_id_to_exercises_map => pool_type_page_id_to_exercises_map,
            :is_valid => is_valid
          }

          return map
        end

        def map_ecosystems(from_ecosystems:, to_ecosystem:)

          # cache each
          ecosystems_maps = from_ecosystems.map do |from_ecosystem|

            # map each
            ecosystem_map = map_ecosystem(from_ecosystem: from_ecosystem, to_ecosystem: to_ecosystem)

            # check validity
            validity, validity_message = validate_maps(to_ecosystem: to_ecosystem,
              exercises: from_ecosystem.exercises, exercises_map: ecosystem_map[:exercise_id_to_page_map],
              pages: from_ecosystem.pages, pages_map: ecosystem_map[:pool_type_page_id_to_exercises_map][:all_exercises],
            )

            ecosystem_map[:is_valid] = validity
            ecosystem_map[:validity_message] = validity_message

            # save map
            Content::Models::Map.create(
              page_id_to_pages_map: ecosystem_map[:page_id_to_pages_map],
              pool_type_page_id_to_exercises_map: ecosystem_map[:pool_type_page_id_to_exercises_map],
              exercise_id_to_page_map: ecosystem_map[:exercise_id_to_page_map],
              content_from_ecosystem_id: from_ecosystem.id, content_to_ecosystem_id: to_ecosystem.id,
              is_valid: validity
            )

            return ecosystem_map
          end

          return ecosystems_maps
        end

        def map_ecosystem(from_ecosystem:, to_ecosystem:)

          all_exercises = from_ecosystem.exercises
          all_pages = from_ecosystem.pages

          page_ids = all_pages.map(&:id)
          exercise_ids = all_exercises.map(&:id)
          from_ecosystems_ids = [from_ecosystem.id]

          page_id_to_pages_map = make_page_id_to_pages_map_for_ecosystem(to_ecosystem)
          exercise_id_to_exercise_map = make_exercise_id_to_exercises_map_for_ecosystem(to_ecosystem)

          # map each
          all_pages_map = make_pages_to_pages_map(
            page_ids: page_ids,
            from_ecosystems_ids: from_ecosystems_ids,
            to_ecosystem: to_ecosystem,
            to_pages: page_id_to_pages_map
          )
          all_exercises_map = make_exercises_to_pages_map(
            exercise_ids: exercise_ids,
            from_ecosystems_ids: from_ecosystems_ids,
            to_ecosystem: to_ecosystem,
            to_pages: page_id_to_pages_map
          )
          all_pages_to_exericises_map = Content::Models::Pool.pool_types.keys.each_with_object({}) do |pool_type, hash|
            hash[pool_type.to_sym] = make_pages_to_exercises_map(
              pages: all_pages,
              page_to_page_map: all_pages_map,
              pool_type: pool_type.to_sym,
              to_ecosystem: to_ecosystem,
              to_exercises: exercise_id_to_exercise_map
            )
          end

          ecosystem_map = {
            :page_id_to_pages_map => all_pages_map,
            :exercise_id_to_page_map => all_exercises_map,
            :pool_type_page_id_to_exercises_map => all_pages_to_exericises_map
          }

          return ecosystem_map
        end

        def map_pages_to_pages(pages:)
          page_ids = pages.map(&:id)

          initialize_page_id_to_pages_map_for_the_to_ecosystem

          mapped_pages = @page_id_to_pages_map.slice(*page_ids)
          unmapped_page_ids = page_ids - mapped_pages.keys

          return mapped_pages # if unmapped_page_ids.empty?

          pages_map = make_pages_to_pages_map(
            page_ids: unmapped_page_ids,
            from_ecosystems_ids: @from_ecosystems.map(&:id),
            to_ecosystem: @to_ecosystem,
            to_pages: @page_id_to_pages_map
          )

          @page_id_to_pages_map.merge!(pages_map)
          @page_id_to_pages_map.slice(*page_ids)
        end

        def map_exercises_to_pages(exercises:)
          exercise_ids = exercises.map(&:id)
          mapped_exercises = @exercise_id_to_page_map.slice(*exercise_ids)
          unmapped_exercise_ids = exercise_ids - mapped_exercises.keys

          return mapped_exercises # if unmapped_exercise_ids.empty?

          initialize_page_id_to_pages_map_for_the_to_ecosystem

          exercises_map = make_exercises_to_pages_map(
            exercise_ids: unmapped_exercise_ids,
            from_ecosystems_ids: @from_ecosystems.map(&:id),
            to_ecosystem: @to_ecosystem,
            to_pages: @page_id_to_pages_map
          )

          @exercise_id_to_page_map.merge!(exercises_map)
          @exercise_id_to_page_map.slice(*exercise_ids)
        end

        def map_pages_to_exercises(pages:, pool_type: :all_exercises)
          page_ids = pages.map(&:id)
          @pool_type_page_id_to_exercises_map[pool_type] ||= {}
          mapped_pages = @pool_type_page_id_to_exercises_map[pool_type].slice(*page_ids)
          unmapped_pages = pages.select{ |pg| mapped_pages[pg.id].nil? }

          return mapped_pages # if unmapped_pages.empty?

          @exercise_id_to_exercise_map ||= make_exercise_id_to_exercises_map_for_ecosystem(@to_ecosystem)

          page_to_page_map = map_pages_to_pages(pages: unmapped_pages)

          page_id_to_exercises_map_for_pool_type = make_pages_to_exercises_map(
            pages: unmapped_pages,
            page_to_page_map: page_to_page_map,
            pool_type: pool_type,
            to_ecosystem: @to_ecosystem,
            to_exercises: @exercise_id_to_exercise_map
          )

          @pool_type_page_id_to_exercises_map[pool_type].merge!(page_id_to_exercises_map_for_pool_type)
          @pool_type_page_id_to_exercises_map[pool_type].slice(*page_ids)
        end

        def valid?
          cached_validity = cache.read(validity_key)
          return cached_validity unless cached_validity.nil?

          validity, validity_message = validate
          cache_validity(validity, validity_message)
          validity
        end

        def validity_diagnostic_message
          cached_validity_message = cache.read(validity_message_key)
          return cached_validity_message unless cached_validity_message.nil?

          validity, validity_message = validate
          cache_validity(validity, validity_message)
          validity_message
        end

        protected

        def initialize_page_id_to_pages_map_for_the_to_ecosystem
          @page_id_to_pages_map = make_page_id_to_pages_map_for_ecosystem(@to_ecosystem) if @page_id_to_pages_map.blank?
        end

        def make_page_id_to_pages_map_for_ecosystem(ecosystem)
          page_id_to_pages_map = ecosystem.pages.each_with_object({}) do |page, hash|
            hash[page.id] = page
          end

          return page_id_to_pages_map
        end

        def make_exercise_id_to_exercises_map_for_ecosystem(ecosystem)
          exercise_id_to_exercises_map = ecosystem.exercises.each_with_object({}) do |exercise, hash|
            hash[exercise.id] = exercise
          end

          return exercise_id_to_exercises_map
        end

        def make_pages_to_pages_map(page_ids:, from_ecosystems_ids:, to_ecosystem:, to_pages:)
          pages_map = {}
          to_pages ||= make_page_id_to_pages_map_for_ecosystem(to_ecosystem)

          page_to_page_map = Content::Models::Page
            .joins(tags: {same_value_tags: :pages})
            .where(tags: {
                     content_ecosystem_id: to_ecosystem.id,
                     tag_type: mapping_tag_types,
                     same_value_tags: {
                       content_ecosystem_id: from_ecosystems_ids,
                       tag_type: mapping_tag_types,
                       pages: {
                         id: page_ids
                       }
                     }
                   })
            .select{[Content::Models::Page.arel_table[Arel.star],
                     tags.same_value_tags.pages.id.as(:unmapped_page_id)]}
            .to_a.group_by(&:unmapped_page_id)

          page_to_page_map.each do |page_id, page_models|
            ecosystem_pages = page_models.map{ |pm| to_pages[pm.id] }.compact.uniq

            # It could happen in theory that a page maps to 2 or more pages,
            # but for now we don't handle that case
            # since it's hard to figure out what to do for the dashboard/scores
            pages_map[page_id] = ecosystem_pages.size == 1 ? ecosystem_pages.first : nil
          end

          return pages_map
        end

        def make_exercises_to_pages_map(exercise_ids:, from_ecosystems_ids:, to_ecosystem:, to_pages:)
          exercises_map = {}
          to_pages ||= make_page_id_to_pages_map_for_ecosystem(to_ecosystem)

          exercise_to_page_map = Content::Models::Page
            .joins(tags: {same_value_tags: :exercises})
            .where(tags: {
                     content_ecosystem_id: to_ecosystem.id,
                     tag_type: mapping_tag_types,
                     same_value_tags: {
                       content_ecosystem_id: from_ecosystems_ids,
                       tag_type: mapping_tag_types,
                       exercises: {
                         id: exercise_ids
                       }
                     }
                   })
            .select{[Content::Models::Page.arel_table[Arel.star],
                     tags.same_value_tags.exercises.id.as(:unmapped_exercise_id)]}
            .to_a.group_by(&:unmapped_exercise_id)

          exercise_to_page_map.each do |exercise_id, page_models|
            ecosystem_pages = page_models.map{ |pm| to_pages[pm.id] }.compact.uniq

            # Each exercise maps to the highest numbered page that shares a mapping tag with it
            exercises_map[exercise_id] = ecosystem_pages.max_by(&:book_location)
          end

          return exercises_map
        end

        def make_pages_to_exercises_map(pages:, page_to_page_map:, pool_type:, to_ecosystem:, to_exercises:)

          pool_type_page_id_to_exercises_map = {}
          page_ids = page_to_page_map.values.compact.map(&:id)

          to_exercises ||= make_exercise_id_to_exercises_map_for_ecosystem(to_ecosystem)

          pool_association = "#{pool_type}_pool".to_sym

          to_page_models = Content::Models::Page.where(id: page_ids)
                                                .joins(pool_association)
                                                .preload(pool_association)

          to_page_to_exercises_map = {}
          to_page_models.each do |to_page|
            pool = to_page.send(pool_association)
            exercises = pool.content_exercise_ids.map{ |ex_id| to_exercises[ex_id] }
            to_page_to_exercises_map[to_page.id] = exercises
          end

          pages.each do |page|
            to_page = page_to_page_map[page.id]
            exercises = to_page_to_exercises_map[to_page.try(:id)] || []
            pool_type_page_id_to_exercises_map[page.id] = exercises
          end

          return pool_type_page_id_to_exercises_map
        end

        def mapping_tag_types
          @mapping_tag_types ||= Content::Models::Tag::MAPPING_TAG_TYPES.map do |type|
            Content::Models::Tag.tag_types[type]
          end
        end

        def cache
          return @cache unless @cache.nil?

          redis_secrets = Rails.application.secrets['redis']
          @cache = ActiveSupport::Cache::RedisStore.new(
            url: redis_secrets['url'], namespace: redis_secrets['namespaces']['cache']
          )
        end

        def cache_key
          "map/#{@from_ecosystems.map(&:id).join('-')}/#{@to_ecosystem.id}"
        end

        def validity_key
          "#{cache_key}/valid"
        end

        def validity_message_key
          "#{cache_key}/validity_message"
        end

        # Valid if:
        # 1- All Exercises in the old Ecosystem map to one Page in the new Ecosystem
        # 2- All Pages in the old Ecosystem map to an array of Exercises in the new Ecosystem
        #    (can be empty)
        def validate
          all_exercises = @from_ecosystems.flat_map(&:exercises)
          all_exercises_map = map_exercises_to_pages(exercises: all_exercises)

          all_pages = @from_ecosystems.flat_map(&:pages)
          all_pages_map = map_pages_to_exercises(pages: all_pages, pool_type: :all_exercises)

          return validate_maps(to_ecosystem: @to_ecosystem,
            exercises: all_exercises, exercises_map: all_exercises_map,
            pages: all_pages, pages_map: all_pages_map,
          )
        end

        def validate_maps(to_ecosystem:, exercises:, exercises_map:, pages:, pages_map:)
          condition_a, condition_a_message = _evaluate_condition_a(exercises, exercises_map)
          condition_b, condition_b_message = _evaluate_condition_b(exercises, exercises_map, to_ecosystem.pages)
          condition_c, condition_c_message = _evaluate_condition_c(pages, pages_map)
          condition_d, condition_d_message = _evaluate_condition_d(pages, pages_map, to_ecosystem.exercises)

          validity = condition_a && condition_b && condition_c && condition_d
          validity_message = "[#{condition_a_message}]" +
                             "[#{condition_b_message}]" +
                             "[#{condition_c_message}]" +
                             "[#{condition_d_message}]"

          return validity, validity_message
        end

        def cache_validity(validity, validity_message)
          cache.write(validity_key, validity)
          cache.write(validity_message_key, validity_message)

          return validity, validity_message
        end

        def _evaluate_condition_a(all_exercises, all_exercises_map)
          ## condition: every exercise appears in the map

          all_exercises_map_ids_set = Set.new(all_exercises_map.keys)
          all_exercise_ids_set      = Set.new(all_exercises.map(&:id))

          condition = all_exercises_map_ids_set == all_exercise_ids_set

          condition_message =
            if condition
              "no unmapped exercises"
            else
              unmapped_exercise_ids = all_exercise_ids_set - all_exercises_map_ids_set
              unmapped_exercise_uids = all_exercises.select{|ex| unmapped_exercise_ids.include? ex.id } \
                                                    .map(&:uid)
              "unmapped exercise uids: #{unmapped_exercise_uids.to_a.join(', ')}"
            end
          return condition, condition_message
        end

        def _evaluate_condition_b(all_exercises, all_exercises_map, to_ecosystem_pages)
          ## condition: every mapped exercise maps to a to_ecosystem page

          all_execises_map_pages_set = Set.new(all_exercises_map.values)
          to_ecosystem_pages_set     = Set.new(to_ecosystem_pages)

          condition = all_execises_map_pages_set.subset?(to_ecosystem_pages_set)

          condition_message =
            if condition
              "all exercises map to pages"
            else
              mismapped_pages = all_execises_map_pages_set - to_ecosystem_pages_set
              mismapped_hash  = all_exercises_map.select{|ex,page| mismapped_pages.include? page }
              diag_info = mismapped_hash.map do |ex_id,page|
                ex_uid = all_exercises.detect{|ex| ex.id == ex_id}.uid
                title  = page.try(:title) || 'nil'
                "#{ex_uid} => #{title}"
              end
              "mismapped exercises: #{diag_info.join(', ')}"
            end
          return condition, condition_message
        end

        def _evaluate_condition_c(all_pages, all_pages_map)
          ## condition: every page appears in the map

          all_pages_map_ids_set = Set.new(all_pages_map.keys)
          all_page_ids_set      = Set.new(all_pages.map(&:id))

          condition = all_pages_map_ids_set == all_page_ids_set

          condition_message =
            if condition
              "no unmapped pages"
            else
              unmapped_page_ids = all_page_ids_set - all_pages_map_ids_set
              unmapped_page_titles = all_pages.select{|page| unmapped_page_ids.include? page.id } \
                                              .map(&:title)
              "unmapped page titles: #{unmapped_page_titles.to_a.join(', ')}"
            end
          return condition, condition_message
        end

        def _evaluate_condition_d(all_pages, all_pages_map, to_ecosystem_exercises)
          ## condition: every mapped page maps to exercises in the to_ecosystem

          all_pages_map_exercises_set = Set.new(all_pages_map.values.flatten)
          to_ecosystem_exercises_set  = Set.new(to_ecosystem_exercises)

          condition = all_pages_map_exercises_set.subset?(to_ecosystem_exercises_set)

          condition_message =
            if condition
              "all pages map to exercise sets"
            else
              mismapped_exercises = all_pages_map_exercises_set - to_ecosystem_exercises_set
              mismapped_hash  = all_pages_map.select{|page,exs| (exs & mismapped_exercises).any? }
              diag_info = mismapped_hash.map do |page_id,exs|
                title = all_pages.detect{|pg| pg.id == page_id}.title
                ex_uids  = exs.map(&:uid)
                "#{title} => [#{ex_uids.join(', ')}]"
              end
              "mismapped pages: #{diag_info.join(', ')}"
            end
          return condition, condition_message
        end

      end
    end
  end
end
