require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ExportExerciseExclusions, type: :routine do
  context "with data" do
    before(:all) do
      @course = FactoryBot.create :course_profile_course
      @teacher_user = FactoryBot.create :user, first_name: "Bob", last_name: "Martin"
      @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher_user]

      chapter = FactoryBot.create :content_chapter

      @book = chapter.book

      @page_1 = FactoryBot.create :content_page, chapter: chapter, book_location: [1, 1]
      @page_2 = FactoryBot.create :content_page, chapter: chapter, book_location: [1, 2]
      @page_removed = FactoryBot.create :content_page, book_location: [42, 1]

      # Creating them in reverse order so @exercise_1 gets the lowest (negative) number
      @exercise_removed = FactoryBot.create :content_exercise, page: @page_removed
      @exercise_3 = FactoryBot.create :content_exercise, page: @page_2
      @exercise_2 = FactoryBot.create :content_exercise, page: @page_2
      @exercise_1 = FactoryBot.create :content_exercise, page: @page_1

      @exercise_another_eco = FactoryBot.create :content_exercise, number: @exercise_1.number

      ecosystem_model = chapter.ecosystem
      ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)
      AddEcosystemToCourse[course: @course, ecosystem: ecosystem]

      @ee_1 = FactoryBot.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise_1.number
      @ee_2 = FactoryBot.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise_2.number
      @ee_3 = FactoryBot.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise_3.number
      @ee_removed = FactoryBot.create :course_content_excluded_exercise,
                                       course: @course, exercise_number: @exercise_removed.number
    end

    let(:outputs) { described_class.call.outputs }

    context "output by course" do
      let(:output) { outputs.by_course.first }

      it "includes the correct keys" do
        expect(output).to include(
          :course_id, :course_name, :teachers, :book_hash,
          :excluded_exercises_count, :excluded_exercises_hash, :page_hashes
        )
      end

      context "returns a (Hashie Mash) hash with the correct data" do
        specify do
          expect(output).to be_a Hashie::Mash
        end

        specify "course id" do
          expect(output).to include(course_id: @course.id)
        end

        specify "course name" do
          expect(output).to include(course_name: @course.name)
        end

        specify "course teachers" do
          expect(output).to include(teachers: @teacher_user.name)
        end

        specify "book hash" do
          expect(output).to include(book_hash: { book_title: @book.title, book_uuid: @book.uuid })
        end

        specify "excluded exercises count" do
          expect(output).to include(excluded_exercises_count: 4)
        end

        context "excluded exercises numbers" do
          let(:ee_numbers) { @course.excluded_exercises.map(&:exercise_number) }

          specify do
            expect(ee_numbers).to_not be_empty
            expect(output[:excluded_exercises_hash].map(&:exercise_number)).to(
              match_array ee_numbers
            )
          end

          specify "with urls" do
            ee_numbers_urls = ee_numbers.map do |number|
              OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
            end
            expect(output[:excluded_exercises_hash].map(&:exercise_url)).to(
              match_array ee_numbers_urls
            )
          end
        end

        context "excluded_ats" do
          let(:excluded_ats) { @course.excluded_exercises.map(&:created_at) }

          specify do
            expect(output[:excluded_ats]).to match_array excluded_ats
          end
        end

        context "page uuids" do
          specify do
            page_uuids = output[:page_hashes].map(&:page_uuid)
            expect(page_uuids).to include(@page_1.uuid)
            expect(page_uuids).to include(@page_2.uuid)
            expect(page_uuids).not_to include(@page_removed.uuid)
            expect(page_uuids).not_to include(@exercise_another_eco.page.uuid)
          end

          specify "with urls" do
            page_urls = output[:page_hashes].map(&:page_url)
            expect(page_urls).to include(OpenStax::Cnx::V1.webview_url_for(@page_1.uuid))
            expect(page_urls).to include(OpenStax::Cnx::V1.webview_url_for(@page_2.uuid))
            expect(page_urls).not_to include(
              OpenStax::Cnx::V1.webview_url_for(@page_removed.uuid)
            )
            expect(page_urls).not_to include(
              OpenStax::Cnx::V1.webview_url_for(@exercise_another_eco.page.uuid)
            )
          end
        end
      end

      context "as csv" do
        it "includes all the correct data" do
          excluded_exercises = @course.excluded_exercises.sort_by(&:exercise_number)
          ee_numbers = excluded_exercises.map(&:exercise_number)
          ee_numbers_urls = ee_numbers.map do |number|
            OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
          end
          exclusion_dates = excluded_exercises.map do |ee|
            DateTimeUtilities.to_api_s(ee.created_at)
          end
          pages = [@page_1, @page_2, @page_2]
          page_uuids = pages.map(&:uuid) + ['null']
          page_urls = pages.map { |page| OpenStax::Cnx::V1.webview_url_for(page.uuid) } + ['null']
          book_locations = pages.map { |page| page.book_location.join('.') } + ['null']

          with_rows_from_csv("by_course") do |rows|
            headers = rows.first
            values = rows.second
            data = Hash[headers.zip(values)]

            expect(data["Course ID"]).to eq @course.id.to_s
            expect(data["Course Name"]).to eq @course.name
            expect(data["Teachers"]).to eq @teacher_user.name
            expect(data["# Exclusions"]).to eq "4"
            expect(data["Excluded Exercise Numbers"].split(", ")).to eq ee_numbers.map(&:to_s)
            expect(data["Excluded Exercise URLs"].split(", ")).to eq ee_numbers_urls
            expect(data["Exclusion Timestamps"].split(", ")).to eq exclusion_dates
            expect(data["CNX Book Title"]).to eq @book.title
            expect(data["CNX Book UUID"]).to eq @book.uuid
            expect(data["CNX Book Locations"].split(", ")).to eq book_locations
            expect(data["CNX Page UUIDs"].split(", ")).to eq page_uuids
            expect(data["CNX Page URLs"].split(", ")).to eq page_urls
          end
        end

        it 'uploads the exported data to Box' do
          # We simply test that the call to Box.upload_files is made properly
          zip_filename_regex = /excluded_exercises_stats_by_course_\d+T\d+Z\.zip/
          filename_regex = /excluded_exercises_stats_by_course_\d+T\d+Z\.csv/
          expect(Box).to receive(:upload_files) do |zip_filename:, files:|
            expect(zip_filename).to match zip_filename_regex
            expect(files.first).to match filename_regex
          end

          described_class.call(upload_by_course: true)
        end
      end
    end

    context "output by exercise" do
      let!(:outputs_by_exercise) { outputs.by_exercise }

      it "includes the correct keys" do
        outputs_by_exercise.each do |output|
          expect(output).to include(
            :exercise_number, :exercise_url, :excluded_exercises_count, :page_hashes
          )
        end
      end

      context "returns a (Hashie Mash) hash with the correct" do
        specify do
          outputs_by_exercise.each{ |output| expect(output).to be_a Hashie::Mash }
        end

        specify "exercise number" do
          exercise_numbers = [@ee_1, @ee_2, @ee_3, @ee_removed].map(&:exercise_number)
          outputs_by_exercise.each do |output|
            expect(output[:exercise_number]).to be_in exercise_numbers
          end
        end

        specify "exercise url" do
          exercise_urls = [@ee_1, @ee_2, @ee_3, @ee_removed].map do |ee|
            OpenStax::Exercises::V1.uri_for("/exercises/#{ee.exercise_number}").to_s
          end
          outputs_by_exercise.each{ |output| expect(output[:exercise_url]).to be_in exercise_urls }
        end

        specify "exclusions count" do
          outputs_by_exercise.each do |output|
            expect(output).to include(excluded_exercises_count: 1)
          end
        end

        context "pages with uuids and urls" do
          it "includes the appropriate uuids" do
            page_uuids = [@page_1, @page_2, @page_removed, @exercise_another_eco.page].map(&:uuid)

            outputs_by_exercise.each do |output|
              output[:page_hashes].map(&:page_uuid).each do |page_uuid|
                expect(page_uuid).to be_in page_uuids
              end
            end
          end

          specify "with urls" do
            page_urls = [@page_1, @page_2, @page_removed, @exercise_another_eco.page].map do |page|
              OpenStax::Cnx::V1.webview_url_for(page.uuid)
            end

            outputs_by_exercise.each do |output|
              output[:page_hashes].map(&:page_url).each do |page_url|
                expect(page_url).to be_in page_urls
              end
            end
          end
        end
      end

      context "as csv" do
        it "includes all the correct data" do
          exercise_numbers = [@ee_1, @ee_2, @ee_3, @ee_removed].map(&:exercise_number)
          exercise_urls = exercise_numbers.map do |exercise_number|
            OpenStax::Exercises::V1.uri_for("/exercises/#{exercise_number}").to_s
          end
          page_uuids = [@page_1, @page_2, @page_removed, @exercise_another_eco.page].map(&:uuid)
          page_urls = page_uuids.map { |page_uuid| OpenStax::Cnx::V1.webview_url_for(page_uuid) }

          with_rows_from_csv("by_exercise") do |rows|
            headers = rows.first
            value_rows = rows[1..-1]
            value_rows.each do |values|
              data = Hash[headers.zip(values)]

              expect(data["Excluded Exercise Number"]).to be_in exercise_numbers.map(&:to_s)
              expect(data["Excluded Exercise URL"]).to be_in exercise_urls
              expect(data["# Exclusions"]).to eq "1"
              data["CNX Page UUIDs"].split(", ").each do |page_uuid|
                expect(page_uuid).to be_in page_uuids
              end
              data["CNX Page URLs"].split(", ").each do |page_url|
                expect(page_url).to be_in page_urls
              end
            end
          end
        end

        it 'uploads the exported data to Box' do
          # We simply test that the call to Box.upload_files is made properly
          zip_filename_regex = /excluded_exercises_stats_by_exercise_\d+T\d+Z\.zip/
          filename_regex = /excluded_exercises_stats_by_exercise_\d+T\d+Z\.csv/
          expect(Box).to receive(:upload_files) do |zip_filename:, files:|
            expect(zip_filename).to match zip_filename_regex
            expect(files.first).to match filename_regex
          end

          described_class.call(upload_by_exercise: true)
        end
      end
    end
  end

  context "without data" do
    it "does not raise an exception" do
      expect{described_class.call}.to_not raise_error
    end
  end
end

def with_rows_from_csv(by_type, &block)
  expect_any_instance_of(described_class).to receive(:remove_exported_files) do |routine|
    filepath = routine.send "local_csv_#{by_type}".to_sym
    expect(File.exist?(filepath)).to be true
    expect(filepath.ends_with? '.csv').to be true
    rows = CSV.read(filepath)
    block.call(rows)
  end

  by_course = by_type == "by_course"
  by_exercise = by_type == "by_exercise"
  expect(Box).to receive(:upload_files)
  described_class.call upload_by_course: by_course, upload_by_exercise: by_exercise
end
