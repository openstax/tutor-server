require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::IReadingAssistant, type: :assistant, vcr: VCR_OPTS do
  before(:all) do
    @assistant = \
      FactoryBot.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant')
  end

  let(:personalized_step_gold_data) do
    [ { group_type: 'personalized_group', klass: Tasks::Models::TaskedPlaceholder } ] * 3
  end

  let(:spaced_practice_step_gold_data) do
    [
      {
        labels: [ 'review' ],
        group_type: 'spaced_practice_group',
        is_core: false,
        klass: Tasks::Models::TaskedPlaceholder
      }
    ] * 3
  end

  let(:task_step_gold_data) do
    core_step_gold_data + personalized_step_gold_data + spaced_practice_step_gold_data
  end

  context 'for Introduction and Force' do
    before(:all) do
      cnx_page_hashes = [
        { 'id' => '1bb611e9-0ded-48d6-a107-fbb9bd900851', 'title' => 'Introduction' },
        { 'id' => '95e61258-2faf-41d4-af92-f62e1414175a', 'title' => 'Force' }
      ]

      cnx_pages = cnx_page_hashes.map{ |hash| OpenStax::Cnx::V1::Page.new(hash: hash) }

      book = FactoryBot.create :content_book, title: 'College Physics with Courseware'

      @ecosystem = book.ecosystem

      @content_pages = VCR.use_cassette(
        'Tasks_Assistants_IReadingAssistant/for_Introduction_and_Force/with_pages', VCR_OPTS
      ) do
        cnx_pages.map.with_index do |cnx_page, ii|
          Content::Routines::ImportPage.call(
            cnx_page:  cnx_page,
            book: book,
            book_indices: [8, ii+1],
            parent_book_part_uuid: SecureRandom.uuid
          ).outputs.page.reload
        end
      end

      Content::Routines::PopulateExercisePools[book: book]
    end

    let(:intro_step_gold_data) do
      {
        klass: Tasks::Models::TaskedReading,
        group_type: 'fixed_group',
        is_core: true,
        title: "Forces and Newton's Laws of Motion",
        related_content: [
          { 'title' => "Forces and Newton's Laws of Motion", 'book_location' => [] }
        ],
        fragment_index: 0
      }
    end

    let(:core_step_gold_data) do
      [
        intro_step_gold_data,
        {
          klass: Tasks::Models::TaskedReading,
          group_type: 'fixed_group',
          is_core: true,
          title: "Force",
          related_content: [ { 'title' => "Force", 'book_location' => [] } ],
          fragment_index: 0
        }
      ]
    end

    let(:task_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: @ecosystem.id,
        settings: { 'page_ids' => @content_pages.map { |page| page.id.to_s } },
        num_tasking_plans: 0
      )
    end

    let(:course) { task_plan.course }

    let(:period) { FactoryBot.create :course_membership_period, course: course }

    let(:num_taskees) { 3 }

    let(:taskee_users) do
      num_taskees.times.map do
        FactoryBot.create(:user_profile).tap do |user|
          AddUserAsPeriodStudent.call(user: user, period: period)
        end
      end
    end

    let!(:tasking_plans) do
      tps = taskee_users.map do |taskee|
        task_plan.tasking_plans << FactoryBot.build(
          :tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee
        )
      end

      task_plan.save!

      tps
    end

    it 'splits a CNX module into many different steps and assigns them with immediate feedback' do
      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      expect(tasks.length).to eq num_taskees

      tasks.each do |task|
        expect(task.taskings.length).to eq 1

        expect(task.feedback_at).to be_nil

        # Preview tasks don't receive Biglearn PEs yet
        next unless task.taskings.first.role.try!(:student).present?

        task_steps = task.task_steps

        expect(task_steps.count).to eq(task_step_gold_data.count)
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.group_type).to eq(task_step_gold_data[ii][:group_type])
          expect(task_step.is_core).to eq(task_step_gold_data[ii][:is_core])
          expect(task_step.labels).to eq(task_step_gold_data[ii][:labels] || [])
          expect(task_step.fragment_index).to eq(task_step_gold_data[ii][:fragment_index])
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          next if task_step.placeholder?

          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
          expect(task_step.related_content).to eq(task_step_gold_data[ii][:related_content])
          expect(task_step.related_exercise_ids).to eq []
        end

        core_task_steps = task.core_task_steps
        expect(core_task_steps.count).to eq(core_step_gold_data.count)

        core_task_steps.each_with_index do |task_step, i|
          page = (i == 0) ? @content_pages.first : @content_pages.last

          expect(task_step.tasked.content).not_to include('snap-lab')

          if task_step.tasked_type.demodulize == 'TaskedExercise'
            expect(page.content).not_to include(task_step.tasked.content)
          end

          if task_step.tasked_type.demodulize == 'TaskedReading'
            expect(task_step.tasked.book_location).to eq(page.book_location)
          end

          other_task_steps = core_task_steps.reject{|ts| ts == task_step}
          other_task_steps.each do |other_step|
            expect(task_step.tasked.content).not_to(
              include(other_step.tasked.content)
            )
          end

        end

        expect(task.personalized_task_steps.count).to eq(personalized_step_gold_data.count)

        expect(task.spaced_practice_task_steps.count).to eq(spaced_practice_step_gold_data.count)
      end

      expected_roles = taskee_users.map{ |tu| Role::GetDefaultUserRole[tu] }
      expect(tasks.map{|task| task.taskings.first.role}).to match_array expected_roles
    end

    it 'does not assign dynamic exercises if the dynamic exercises pool is empty' do
      task_plan.update_attribute(:settings, { 'page_ids' => [@content_pages.first.id.to_s] })
      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      expect(tasks.length).to eq num_taskees

      tasks.each do |task|
        expect(task.taskings.length).to eq 1

        expect(task.feedback_at).to be_nil

        # Preview tasks don't receive Biglearn PEs yet
        next unless task.taskings.first.role.try!(:student).present?

        task_steps = task.task_steps

        expect(task_steps.count).to eq 1
        expect(task.core_task_steps.count).to eq 1
        expect(task.spaced_practice_task_steps.count).to eq 0
        expect(task.personalized_task_steps.count).to eq 0

        task_step = task_steps.first
        expect(task_step.group_type).to eq(intro_step_gold_data[:group_type])
        expect(task_step.is_core).to eq(task_step_gold_data[ii][:is_core])
        expect(task_step.tasked.class).to eq(intro_step_gold_data[:klass])

        expect(task_step.tasked.title).to eq(intro_step_gold_data[:title])
        expect(task_step.related_content).to eq(intro_step_gold_data[:related_content])
        expect(task_step.related_exercise_ids).to eq []

        expect(task_step.is_core?).to eq true
      end

      expected_roles = taskee_users.map{ |tu| Role::GetDefaultUserRole[tu] }
      expect(tasks.map{ |task| task.taskings.first.role }).to match_array expected_roles
    end
  end

  context "for Newton's First Law of Motion: Inertia" do
    let(:cnx_page_hash) do
      {
        'id' => '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
        'title' => "Newton's First Law of Motion: Inertia"
      }
    end

    let(:core_step_gold_data) do
      [
        {
          klass: Tasks::Models::TaskedReading,
          group_type: 'fixed_group',
          is_core: true,
          title: "Newton's First Law of Motion: Inertia",
          fragment_index: 0
        },
        {
          klass: Tasks::Models::TaskedVideo,
          group_type: 'fixed_group',
          is_core: true,
          title: "Newton’s First Law of Motion",
          fragment_index: 0
        },
        {
          klass: Tasks::Models::TaskedExercise,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          fragment_index: 1
        },
        {
          klass: Tasks::Models::TaskedInteractive,
          group_type: 'fixed_group',
          is_core: true,
          title: "Virtual Physics: Forces and Motion: Basics",
          fragment_index: 2
        },
        {
          klass: Tasks::Models::TaskedExercise,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          fragment_index: 3
        }
      ]
    end

    let(:cnx_page)  { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

    let(:book)      { FactoryBot.create :content_book, title: 'College Physics with Courseware' }

    let(:ecosystem) { book.ecosystem }

    let(:page) do
      Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        book: book,
        book_indices: [1, 1],
        parent_book_part_uuid: SecureRandom.uuid
      ).outputs.page.reload
    end

    let!(:pools) { Content::Routines::PopulateExercisePools[book: page.book] }

    let(:task_plan) do
      FactoryBot.build(:tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: ecosystem.id,
        settings: { 'page_ids' => [page.id.to_s] },
        num_tasking_plans: 0
      )
    end

    let(:course) { task_plan.course }

    let(:period) { FactoryBot.create :course_membership_period, course: course }

    let(:num_taskees) { 3 }

    let(:taskee_users) do
      num_taskees.times.map do
        FactoryBot.create(:user_profile).tap do |profile|
          AddUserAsPeriodStudent.call(user: profile, period: period)
        end
      end
    end

    let!(:tasking_plans) do
      taskee_users.map do |taskee|
        task_plan.tasking_plans << FactoryBot.build(
          :tasks_tasking_plan, task_plan: task_plan, target: taskee
        )
      end.tap { task_plan.save! }
    end

    it 'is split into different task steps with immediate feedback' do
      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      tasks.each do |task|
        expect(task.taskings.length).to eq 1
        expect(task.feedback_at).to be_nil

        # Preview tasks don't receive Biglearn PEs yet
        next unless task.taskings.first.role.try!(:student).present?

        task_steps = task.task_steps

        expect(task_steps.count).to eq task_step_gold_data.count
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.group_type).to eq(task_step_gold_data[ii][:group_type])
          expect(task_step.is_core).to eq(task_step_gold_data[ii][:is_core])
          expect(task_step.labels).to eq(task_step_gold_data[ii][:labels] || [])
          expect(task_step.fragment_index).to eq(task_step_gold_data[ii][:fragment_index])
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          next if task_step.placeholder?

          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
          expect(task_step.related_exercise_ids).to eq []
        end
      end
    end

  end

  context "for Newton's Second Law of Motion" do
    let(:cnx_page_hash) do
      {
        'id' => '548a8717-71e1-4d65-80f0-7b8c6ed4b4c0',
        'title' => "Newton's Second Law of Motion"
      }
    end

    let(:cnx_page)  { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

    let(:book)      { FactoryBot.create :content_book, title: 'College Physics with Courseware' }

    let(:ecosystem) { book.ecosystem }

    let(:page) do
      Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        book: book,
        book_indices: [1, 1],
        parent_book_part_uuid: SecureRandom.uuid
      ).outputs.page.reload
    end

    let!(:pools) { Content::Routines::PopulateExercisePools[book: page.book] }

    let(:task_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: ecosystem.id,
        settings: { 'page_ids' => [page.id.to_s] },
        num_tasking_plans: 0
      )
    end

    let(:course) { task_plan.course }

    let(:period) { FactoryBot.create :course_membership_period, course: course }

    let(:num_taskees) { 3 }

    let(:taskee_users) do
      num_taskees.times.map do
        FactoryBot.create(:user_profile).tap do |profile|
          AddUserAsPeriodStudent.call(user: profile, period: period)
        end
      end
    end

    let!(:tasking_plans) do
      tps = taskee_users.map do |taskee|
        task_plan.tasking_plans << FactoryBot.build(
          :tasks_tasking_plan, task_plan: task_plan, target: taskee
        )
      end

      task_plan.save!
      tps
    end

    let(:core_step_gold_data) do
      reading_context_exercise_ids = page.reload.reading_context_exercise_ids
      reading_context_exercises = page.exercises.where(
        id: reading_context_exercise_ids
      ).preload(:tags)

      [
        {
          klass: Tasks::Models::TaskedReading,
          group_type: 'fixed_group',
          is_core: true,
          title: "Newton's Second Law of Motion",
          related_exercise_ids: [],
          fragment_index: 0
        },
        {
          klass: Tasks::Models::TaskedVideo,
          group_type: 'fixed_group',
          is_core: true,
          title: "Newton’s Second Law of Motion",
          related_exercise_ids: [],
          fragment_index: 0
        },
        {
          klass: Tasks::Models::TaskedExercise,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          related_exercise_ids: [],
          fragment_index: 1
        },
        {
          klass: Tasks::Models::TaskedReading,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          related_exercise_ids: [],
          fragment_index: 2
        },
        {
          klass: Tasks::Models::TaskedExercise,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          related_exercise_ids: reading_context_exercises.filter do |exercise|
            exercise.tags.map(&:value).include?('k12phys-ch04-s03-lo02')
          end.map(&:id),
          fragment_index: 3
        }
      ]
    end

    it 'is split into different task steps with immediate feedback and a "try another" exercise' do
      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      tasks.each do |task|
        expect(task.taskings.length).to eq 1
        expect(task.feedback_at).to be_nil

        # Preview tasks don't receive Biglearn PEs yet
        next unless task.taskings.first.role.try!(:student).present?

        task_steps = task.task_steps

        expect(task_steps.count).to eq task_step_gold_data.count
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.group_type).to eq(task_step_gold_data[ii][:group_type])
          expect(task_step.is_core).to eq(task_step_gold_data[ii][:is_core])
          expect(task_step.labels).to eq(task_step_gold_data[ii][:labels] || [])
          expect(task_step.fragment_index).to eq(task_step_gold_data[ii][:fragment_index])
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          next if task_step.placeholder?

          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
          expect(Set.new task_step.related_exercise_ids).to(
            eq Set.new(task_step_gold_data[ii][:related_exercise_ids])
          )
        end
      end
    end

  end

  context "for a fake cnx page" do
    let(:reading_content) do
      "Read about Newton's Flaming Laser Sword on
       <a href=\"https://en.wikipedia.org/wiki/Mike_Alder#Newton.27s_flaming_laser_sword\">
         Wikipedia
       </a>"
    end
    let(:video_content) do
      '<div id="fs-video">
         <iframe src="https://www.youtube.com/embed/C00l_Vid/"></iframe>
       </div>'
    end
    let(:interactive_content) do
      '<div id="fs-interactive">
         <iframe src="https://connexions.github.io/simulations/nfls/"></iframe>
       </div>'
    end

    let(:page) do
      FactoryBot.create :content_page, title: "Newton's Flaming Laser Sword"
    end
    let(:book)       { page.book }
    let(:ecosystem)  { book.ecosystem }

    let(:cnxmod_tag) do
      FactoryBot.create(:content_tag, value: "context-cnxmod:#{page.uuid}",
                                       tag_type: :cnxmod,
                                       ecosystem: ecosystem).tap do |tag|
        page.tags << tag
      end
    end
    let!(:video_exercise_id_tag) do
      FactoryBot.create :content_tag, value: 'k12phys-ch99-ex01',
                                       tag_type: :id,
                                       ecosystem: ecosystem
    end
    let!(:video_cnxfeature_tag) do
      FactoryBot.create :content_tag, value: "context-cnxfeature:fs-video",
                                       tag_type: :cnxfeature,
                                       ecosystem: ecosystem
    end
    let!(:interactive_cnxfeature_tag) do
      FactoryBot.create :content_tag, value: "context-cnxfeature:fs-interactive",
                                       tag_type: :cnxfeature,
                                       ecosystem: ecosystem
    end

    let!(:video_exercise) do
      FactoryBot.create(:content_exercise, page: page, context: video_content).tap do |exercise|
        exercise.tags << cnxmod_tag
        exercise.tags << video_exercise_id_tag
        exercise.tags << video_cnxfeature_tag
      end
    end
    let!(:interactive_exercise) do
      FactoryBot.create(:content_exercise, page: page,
                                            context: interactive_content).tap do |exercise|
        exercise.tags << cnxmod_tag
        exercise.tags << interactive_cnxfeature_tag
      end
    end

    let(:task_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: ecosystem.id,
        settings: { 'page_ids' => [page.id.to_s] },
        num_tasking_plans: 0
      )
    end

    let(:course) { task_plan.course }

    let(:period) { FactoryBot.create :course_membership_period, course: course }

    let(:taskee_user) do
      FactoryBot.create(:user_profile).tap do |profile|
        AddUserAsPeriodStudent.call(user: profile, period: period)
      end
    end

    let!(:tasking_plan) do
      tasking_plan = FactoryBot.build(
        :tasks_tasking_plan, task_plan: task_plan, target: taskee_user
      )

      task_plan.tasking_plans << tasking_plan
      task_plan.save!

      tasking_plan
    end

    # The gaps in the fragment indices are caused by exercises combining with previous page content
    let(:task_step_gold_data) do
      [
        {
          klass: Tasks::Models::TaskedReading,
          group_type: 'fixed_group',
          is_core: true,
          title: "Newton's Flaming Laser Sword",
          fragment_index: 0
        },
        {
          klass: Tasks::Models::TaskedExercise,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          fragment_index: 2
        },
        {
          klass: Tasks::Models::TaskedExercise,
          group_type: 'fixed_group',
          is_core: true,
          title: nil,
          fragment_index: 4
        },
        {
          klass: Tasks::Models::TaskedPlaceholder,
          group_type: 'spaced_practice_group',
          is_core: false,
          title: nil,
          labels: [ 'review' ]
        },
        {
          klass: Tasks::Models::TaskedPlaceholder,
          group_type: 'spaced_practice_group',
          is_core: false,
          title: nil,
          labels: [ 'review' ]
        },
        {
          klass: Tasks::Models::TaskedPlaceholder,
          group_type: 'spaced_practice_group',
          is_core: false,
          title: nil,
          labels: [ 'review' ]
        }
      ]
    end

    it 'combines exercises with context with the previous step when possible' do
      node = Nokogiri::HTML.fragment(
        "<div class=\"exercise\">
           <a href=#ost/api/ex/#{video_exercise_id_tag.value}>[Link]</a>
         </div>"
      )
      OpenStax::Cnx::V1::Fragment::Exercise.absolutize_exercise_urls! node

      allow_any_instance_of(Content::Models::Page).to receive(:fragments) do
        [
          OpenStax::Cnx::V1::Fragment::Reading.new(
            node: Nokogiri::HTML.fragment(reading_content).children.first,
            title: "Doesn't matter, the first fragment's title comes from the page"
          ),
          OpenStax::Cnx::V1::Fragment::Video.new(
            node: Nokogiri::HTML.fragment(video_content).children.first,
            title: "Watch Isaac Newton use the Force against Robert Hooke"
          ),
          OpenStax::Cnx::V1::Fragment::Exercise.new(
            node: node.children.first,
            title: nil
          ),
          OpenStax::Cnx::V1::Fragment::Interactive.new(
            node: Nokogiri::HTML.fragment(interactive_content).children.first,
            title: "Now try it yourself"
          ),
          OpenStax::Cnx::V1::Fragment::Exercise.new(
            node: Nokogiri::HTML.fragment(interactive_content).children.first,
            title: nil
          )
        ]
      end

      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      expect(tasks.size).to eq 1
      task_steps = tasks.first.task_steps

      expect(task_steps.count).to eq task_step_gold_data.count
      task_steps.each_with_index do |task_step, ii|
        expect(task_step.group_type).to eq(task_step_gold_data[ii][:group_type])
        expect(task_step.is_core).to eq(task_step_gold_data[ii][:is_core])
        expect(task_step.labels).to eq(task_step_gold_data[ii][:labels] || [])
        expect(task_step.fragment_index).to eq(task_step_gold_data[ii][:fragment_index])
        expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
        next if task_step.placeholder?

        expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
      end
    end
  end
end
