require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe ExportAndUploadResearchData, type: :routine, speed: :medium do
  before(:all) do
    @course = FactoryBot.create :course_profile_course, :with_assistants, timezone: 'US/Central'

    @teacher = FactoryBot.create :user_profile

    @student_1 = FactoryBot.create :user_profile, first_name: 'Student',
                                          last_name: 'One',
                                          full_name: 'Student One'

    @student_2 = FactoryBot.create :user_profile, first_name: 'Student',
                                          last_name: 'Two',
                                          full_name: 'Student Two'

    @student_3 = FactoryBot.create :user_profile, first_name: 'Student',
                                          last_name: 'Three',
                                          full_name: 'Student Three'

    @student_4 = FactoryBot.create :user_profile, first_name: 'Student',
                                          last_name: 'Four',
                                          full_name: 'Student Four'
  end

  let(:all_task_types) { Tasks::Models::Task.task_types.values }

  # Cover each_batch in the spec
  before { stub_const("#{described_class.name}::BATCH_SIZE", 3) }

  context 'with book and performance report data' do
    before(:all) do
      DatabaseCleaner.start
      @ecosystem = generate_mini_ecosystem

      CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

      SetupPerformanceReportData[course: @course,
                                 teacher: @teacher,
                                 students: [@student_1, @student_2, @student_3, @student_4],
                                 ecosystem: @ecosystem]
    end

    after(:all) { DatabaseCleaner.clean }

    context 'Tutor export' do
      let(:export) { :tutor }

      it 'exports data to Box as a csv file' do
        # We replace the uploading of the research data with the test case itself
        with_export_rows(export, all_task_types) do |rows|
          headers = rows.first

          step_id_index = headers.index('Step ID')
          step_ids = rows.map { |row| row[step_id_index] }
          steps_by_id = Tasks::Models::TaskStep
            .where(id: step_ids)
            .preload(:tasked, task: [ :course, taskings: :role ])
            .index_by(&:id)

          period_ids = @course.periods.map { |period| period.id.to_s }

          rows[1..-1].each do |row|
            data = headers.zip(row).to_h
            step = steps_by_id.fetch(data['Step ID'].to_i)
            page_url = step.page.try!(:url)
            page_json_url = "#{page_url}.json" unless page_url.nil?
            task = step.task
            tasked = step.tasked
            correct_answer_id = step.exercise? ? tasked.correct_answer_id : nil
            answer_id = step.exercise? ? tasked.answer_id : nil
            correct = step.exercise? && step.completed? ? (tasked.is_correct? ? 1 : 0).to_s : nil
            free_response = step.exercise? ? tasked.free_response : nil
            # Exercises in this cassette get assigned to pages by their lo tag, not cnxmod tag
            tags = step.exercise? ?
                   tasked.tags.map(&:value).reject { |tag| tag.start_with? 'context-cnxmod' } : []

            expect(data['Student Research Identifier']).to(
              eq(task.taskings.first.role.research_identifier)
            )
            expect(data['Course ID']).to eq(@course.id.to_s)
            expect(data['Period ID']).to be_in(period_ids)
            expect(data['Plan ID']).to eq(task.task_plan.try!(:id).try!(:to_s))
            expect(data['Task ID'].to_i).to eq(task.id)
            expect(data['Task Type']).to eq(task.task_type)
            expect(data['Task Opens At']).to eq(format_time(task.opens_at))
            expect(data['Task Due At']).to eq(format_time(task.due_at))
            expect(data['Task Closes At']).to eq(format_time(task.closes_at))
            expect(data['Step Type']).to eq(step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1))
            expect(data['Step Group']).to eq(step.group_name)
            expect(data['Step Labels']).to eq(step.labels.join(','))
            expect(data['Step First Completed At']).to eq(format_time(step.first_completed_at))
            expect(data['Step Last Completed At']).to eq(format_time(step.last_completed_at))
            expect(data['CNX JSON URL']).to eq(page_json_url)
            expect(data['CNX HTML URL']).to eq(page_url)
            expect(data['HTML Fragment Number']).to eq(step.fragment_index.try!(:+, 1).try!(:to_s))
            next unless step.exercise?

            expect(data['Exercise JSON URL']).to eq("#{tasked.url.gsub("org", "org/api")}.json")
            expect(data['Exercise Editor URL']).to eq(tasked.url)
            expect((data['Exercise Tags'] || '').split(',').reject { |tag| tag.start_with? 'context-cnxmod' }).to match_array(tags)
            expect(data['Question Number']).to eq '1'
            expect(data['Question Correct Answer ID']).to eq(correct_answer_id)
            expect(data['Question Chosen Answer ID']).to eq(answer_id)
            expect(data['Question Correct?']).to eq(correct)
            expect(data['Question Free Response']).to eq(free_response)
          end
        end
      end
    end

    context 'CNX export' do
      let(:export) { :cnx }

      it 'exports data to Box as a csv file' do
        # We replace the uploading of the research data with the test case itself
        with_export_rows(export, all_task_types) do |rows|
          headers = rows.first

          url_index = headers.index('CNX HTML URL')
          page_urls = rows.map { |row| row[url_index] }
          pages_by_url = Content::Models::Page
            .select('DISTINCT ON ("content_pages"."url") *')
            .where(url: page_urls)
            .preload(:book)
            .index_by(&:url)

          period_ids = @course.periods.map { |period| period.id.to_s }

          rows[1..-1].each do |row|
            data = headers.zip(row).to_h
            page = pages_by_url.fetch(data['CNX HTML URL'])
            book = page.book
            fragment = page.fragments[data['HTML Fragment Number'].to_i - 1]

            expect(data['CNX JSON URL']).to eq("#{page.url}.json")
            expect(data['CNX Book Name']).to eq(book.title)
            expect(data['CNX Section Number']).to eq(page.book_location.join('.'))
            expect(data['CNX Section Name']).to eq(page.title)
            expect(data['HTML Fragment Labels']).to eq(fragment.labels.join(','))
            expect(data['HTML Fragment Content']).to eq(fragment.try(:to_html))
          end
        end
      end
    end

    context 'Exercises export' do
      let(:export) { :exercises }

      it 'exports data to Box as a csv file' do
        # We replace the uploading of the research data with the test case itself
        with_export_rows(export, all_task_types) do |rows|
          headers = rows.first

          exercise_number_index = headers.index('Exercise Number')
          exercise_numbers = rows.map { |row| row[exercise_number_index] }
          exercises_by_number_and_version = Hash.new { |hash, key| hash[key] = {} }
          Content::Models::Exercise
            .select('DISTINCT ON ("content_exercises"."number", "content_exercises"."version") *')
            .where(number: exercise_numbers)
            .each do |exercise|
            exercises_by_number_and_version[exercise.number][exercise.version] = exercise
          end

          rows[1..-1].each do |row|
            data = headers.zip(row).to_h
            number = data['Exercise Number'].to_i
            version = data['Exercise Version'].to_i
            exercise = exercises_by_number_and_version.fetch(number).fetch(version)

            tags = exercise.content_hash['tags'].join(',')
            stimulus = exercise.content_hash['stimulus_html']
            json = exercise.content

            expect(data['Exercise Tags']).to eq tags
            expect(data['Exercise Stimulus HTML']).to eq stimulus
            expect(data['Exercise JSON']).to eq json

            question_index = data['Question Number'].to_i - 1
            question = exercise.questions[question_index]

            solution = (question['collaborator_solutions'] || []).first

            expect(data['Question Stem HTML']).to eq question['stem_html']
            expect(data['Question Solution HTML']).to eq solution.try!(:[], 'content_html') || ''
            expect(data['Question Answer Order Important?']).to(
              eq (question['is_answer_order_important'] ? 1 : 0).to_s
            )

            correct_answers = []
            question['answers'].each_with_index do |answer, ii|
              correct_answers << ii + 1 if answer['correctness'].to_f == 1.0

              expect(data["Answer #{ii + 1} ID"]).to eq answer['id'].to_s
              expect(data["Answer #{ii + 1} Content HTML"]).to eq answer['content_html']
              expect(data["Answer #{ii + 1} Feedback"]).to eq answer['feedback_html']
            end

            expect(data['Question Correct Answer Numbers']).to eq correct_answers.join(',')
          end
        end
      end
    end
  end

  context 'with filterable data' do
    before(:all) do
      DatabaseCleaner.start

      Timecop.freeze(Date.today - 30) do
        old_reading_task = FactoryBot.create :tasks_task, step_types: [:tasks_tasked_reading],
                                                          num_random_taskings: 1
        page = old_reading_task.task_steps.first.page
        Content::Routines::TransformAndCachePageContent.call book: page.book
        FactoryBot.create :tasks_task_step, task: old_reading_task, page: page

        student = old_reading_task.taskings.first.role.student
        student.update_attribute :course, @course
      end

      cc_tasks = 2.times.map do
        FactoryBot.create(:tasks_task, task_type: :concept_coach,
                                       step_types: [:tasks_tasked_exercise],
                                       num_random_taskings: 1).tap do |cc_task|
          page = cc_task.task_steps.first.page
          Content::Routines::TransformAndCachePageContent.call book: page.book
          FactoryBot.create :tasks_task_step, task: cc_task,
                                              page: page,
                                              tasked_type: :tasks_tasked_exercise
        end
      end

      reading_task = FactoryBot.create :tasks_task, task_type: :reading,
                                                    step_types: [:tasks_tasked_reading],
                                                    num_random_taskings: 1
      page = reading_task.task_steps.first.page
      Content::Routines::TransformAndCachePageContent.call book: page.book
      FactoryBot.create :tasks_task_step, task: reading_task,
                                          page: reading_task.task_steps.first.page

      (cc_tasks + [reading_task]).each do |task|
        student = task.taskings.first.role.student
        student.update_attribute :course, @course
      end

      expect(Tasks::Models::TaskStep.count).to eq 8
    end

    after(:all) { DatabaseCleaner.clean }

    context 'Tutor export' do
      let(:export) { :tutor }

      specify 'by date range' do
        with_export_rows(export, all_task_types, Date.today - 10, Date.tomorrow) do |rows|
          expect(rows.count - 1).to eq(6)
        end
      end

      context 'by application' do
        let(:tutor_task_types) do
          Tasks::Models::Task.task_types.values_at(
            :homework, :reading, :chapter_practice, :page_practice,
            :mixed_practice, :external, :event, :extra
          )
        end
        let(:cc_task_types) { Tasks::Models::Task.task_types.values_at(:concept_coach) }

        specify 'only Concept Coach' do
          with_export_rows(export, cc_task_types) do |rows|
            expect(rows.count - 1).to eq(4)
          end
        end

        specify 'only Tutor' do
          with_export_rows(export, tutor_task_types) do |rows|
            expect(rows.count - 1).to eq(4)
          end
        end

        specify 'Tutor and Concept Coach' do
          with_export_rows(export, all_task_types) do |rows|
            expect(rows.count - 1).to eq(8)
          end
        end
      end
    end

    context 'CNX export' do
      let(:export) { :cnx }

      specify 'by date range' do
        with_export_rows(export, all_task_types, Date.today - 10, Date.tomorrow) do |rows|
          expect(rows.count - 1).to eq(3)
        end
      end

      context 'by application' do
        let(:tutor_task_types) do
          Tasks::Models::Task.task_types.values_at(
            :homework, :reading, :chapter_practice, :page_practice,
            :mixed_practice, :external, :event, :extra
          )
        end
        let(:cc_task_types) { Tasks::Models::Task.task_types.values_at(:concept_coach) }

        specify 'only Concept Coach' do
          with_export_rows(export, cc_task_types) do |rows|
            expect(rows.count - 1).to eq(2)
          end
        end

        specify 'only Tutor' do
          with_export_rows(export, tutor_task_types) do |rows|
            expect(rows.count - 1).to eq(2)
          end
        end

        specify 'Tutor and Concept Coach' do
          with_export_rows(export, all_task_types) do |rows|
            expect(rows.count - 1).to eq(4)
          end
        end
      end
    end

    context 'Exercises export' do
      let(:export) { :exercises }

      specify 'by date range' do
        with_export_rows(export, all_task_types, Date.today - 10, Date.tomorrow) do |rows|
          expect(rows.count - 1).to eq(4)
        end
      end

      context 'by application' do
        let(:tutor_task_types) do
          Tasks::Models::Task.task_types.values_at(
            :homework, :reading, :chapter_practice, :page_practice,
            :mixed_practice, :external, :event, :extra
          )
        end
        let(:cc_task_types) { Tasks::Models::Task.task_types.values_at(:concept_coach) }

        specify 'only Concept Coach' do
          with_export_rows(export, cc_task_types) do |rows|
            expect(rows.count - 1).to eq(4)
          end
        end

        specify 'only Tutor' do
          with_export_rows(export, tutor_task_types) do |rows|
            expect(rows.count - 1).to eq(0)
          end
        end

        specify 'Tutor and Concept Coach' do
          with_export_rows(export, all_task_types) do |rows|
            expect(rows.count - 1).to eq(4)
          end
        end
      end
    end
  end

  def with_export_rows(export, task_types, from = nil, to = nil, &block)
    expect(Box).to receive(:upload_files) do |zip_filename:, files:|
      file = files.find { |file| file.include? export.to_s }
      expect(File.exist?(file)).to be true
      expect(file.ends_with? '.csv').to be true
      rows = CSV.read(file)
      block.call(rows)
    end

    described_class.call(task_types: task_types, from: from.to_s, to: to.to_s)
  end

  def format_time(time)
    return time if time.blank?
    time.utc.iso8601
  end
end
