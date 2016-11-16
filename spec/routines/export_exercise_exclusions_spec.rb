require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ExportExerciseExclusions, type: :routine do
  before(:each) do
    WebMock.disable_net_connect!
    stub_request(:put, /remote.php/).to_return(status: 200)
  end

  context "with data" do
    before(:all) do
      @course = FactoryGirl.create :course_profile_course
      @teacher_user = FactoryGirl.create :user, first_name: "Bob", last_name: "Martin"
      @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher_user]

      chapter = FactoryGirl.create :content_chapter

      @page_1 = FactoryGirl.create :content_page, chapter: chapter
      @page_2 = FactoryGirl.create :content_page, chapter: chapter
      @page_3 = FactoryGirl.create :content_page, chapter: chapter

      @exercise_1 = FactoryGirl.create :content_exercise, page: @page_1
      @exercise_2 = FactoryGirl.create :content_exercise, page: @page_2
      @exercise_3 = FactoryGirl.create :content_exercise, page: @page_3

      @exercise_another_eco = FactoryGirl.create :content_exercise, number: @exercise_1.number

      ecosystem_model = chapter.ecosystem
      ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)
      AddEcosystemToCourse[course: @course, ecosystem: ecosystem]

      @ee_1 = FactoryGirl.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise_1.number
      @ee_2 = FactoryGirl.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise_2.number
      @ee_3 = FactoryGirl.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise_3.number
    end

    let(:outputs){ described_class.call.outputs }

    context "output by course" do
      let(:output) { outputs.by_course.first }

      it "includes the correct keys" do
        expect(output).to include(
          :course_id, :course_name, :teachers, :excluded_exercises_count,
          :excluded_exercises_numbers_with_urls, :page_uuids_with_urls
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

        specify "excluded exercises count" do
          expect(output).to include(excluded_exercises_count: 3)
        end

        context "excluded exercises numbers" do
          specify do
            ee_numbers = @course.excluded_exercises.map(&:exercise_number)
            expect(ee_numbers).to_not be_empty
            expect(output[:excluded_exercises_numbers_with_urls].map(&:exercise_number)).to(
              match_array ee_numbers
            )
          end

          specify "with urls" do
            ee_numbers = @course.excluded_exercises.map(&:exercise_number)
            ee_numbers_urls = ee_numbers.map do |number|
              OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
            end
            expect(output[:excluded_exercises_numbers_with_urls].map(&:exercise_url)).to(
              match_array ee_numbers_urls
            )
          end
        end

        context "page uuids" do
          specify do
            page_uuids = output[:page_uuids_with_urls].map(&:page_uuid)
            expect(page_uuids).to include(@exercise_1.page.uuid)
            expect(page_uuids).to include(@exercise_2.page.uuid)
            expect(page_uuids).to include(@exercise_3.page.uuid)
            expect(page_uuids).not_to include(@exercise_another_eco.page.uuid)
          end

          specify "with urls" do
            page_urls = output[:page_uuids_with_urls].map(&:page_url)
            expect(page_urls).to include(OpenStax::Cnx::V1.webview_url_for(@exercise_1.page.uuid))
            expect(page_urls).to include(OpenStax::Cnx::V1.webview_url_for(@exercise_2.page.uuid))
            expect(page_urls).to include(OpenStax::Cnx::V1.webview_url_for(@exercise_3.page.uuid))
            expect(page_urls).not_to include(
              OpenStax::Cnx::V1.webview_url_for(@exercise_another_eco.page.uuid)
            )
          end
        end
      end

      context "as csv" do
        it "includes all the correct data" do
          ee_numbers = @course.excluded_exercises.map(&:exercise_number)
          ee_numbers_urls = ee_numbers.map do |number|
            OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
          end
          page_uuids = [@page_1, @page_2, @page_3].map(&:uuid)
          page_urls = page_uuids.map{ |page_uuid| OpenStax::Cnx::V1.webview_url_for(page_uuid) }

          with_rows_from_csv("by_course") do |rows|
            headers = rows.first
            values = rows.second
            data = Hash[headers.zip(values)]

            expect(data["Course ID"]).to eq @course.id.to_s
            expect(data["Course Name"]).to eq @course.name
            expect(data["Teachers"]).to eq @teacher_user.name
            expect(data["# Exclusions"]).to eq "3"
            expect(data["Excluded Numbers"].split(", ")).to match_array ee_numbers.map(&:to_s)
            expect(data["Excluded Numbers URLs"].split(", ")).to match_array ee_numbers_urls
            expect(data["CNX Section UUID"].split(", ")).to match_array page_uuids
            expect(data["CNX Section UUID URLs"].split(", ")).to match_array page_urls
          end
        end

        it 'uploads the exported data to owncloud' do
          file_regex_string = 'excluded_exercises_stats_by_course_\d+T\d+Z.csv'
          webdav_url_regex = Regexp.new "#{described_class::WEBDAV_BASE_URL}/#{file_regex_string}"

          # We simply test that the call to HTTParty is made properly
          expect(HTTParty).to receive(:put).with(
            webdav_url_regex,
            basic_auth: { username: a_kind_of(String).or(be_nil),
                          password: a_kind_of(String).or(be_nil) },
            body_stream: a_kind_of(File),
            headers: { 'Transfer-Encoding' => 'chunked' }
          ).and_return OpenStruct.new(success?: true)

          described_class.call(upload_by_course_to_owncloud: true)
        end
      end
    end

    context "output by exercise" do
      let!(:outputs_by_exercise) { outputs.by_exercise }

      it "includes the correct keys" do
        outputs_by_exercise.each do |output|
          expect(output).to include(
            :exercise_number, :exercise_url, :excluded_exercises_count, :pages_with_uuids_and_urls
          )
        end
      end

      context "returns a (Hashie Mash) hash with the correct" do
        specify do
          outputs_by_exercise.each{ |output| expect(output).to be_a Hashie::Mash }
        end

        specify "exercise number" do
          exercise_numbers = [@ee_1, @ee_2, @ee_3].map(&:exercise_number)
          outputs_by_exercise.each do |output|
            expect(output[:exercise_number]).to be_in exercise_numbers
          end
        end

        specify "exercise url" do
          exercise_urls = [@ee_1, @ee_2, @ee_3].map do |ee|
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
            page_uuids = [@page_1, @page_2, @page_3, @exercise_another_eco.page].map(&:uuid)

            outputs_by_exercise.each do |output|
              output[:pages_with_uuids_and_urls].map(&:page_uuid).each do |page_uuid|
                expect(page_uuid).to be_in page_uuids
              end
            end
          end

          specify "with urls" do
            page_urls = [@page_1, @page_2, @page_3, @exercise_another_eco.page].map do |page|
              OpenStax::Cnx::V1.webview_url_for(page.uuid)
            end

            outputs_by_exercise.each do |output|
              output[:pages_with_uuids_and_urls].map(&:page_url).each do |page_url|
                expect(page_url).to be_in page_urls
              end
            end
          end
        end
      end

      context "as csv" do
        it "includes all the correct data" do
          exercise_numbers = [@ee_1, @ee_2, @ee_3].map(&:exercise_number)
          exercise_urls = exercise_numbers.map do |exercise_number|
            OpenStax::Exercises::V1.uri_for("/exercises/#{exercise_number}").to_s
          end
          page_uuids = [@page_1, @page_2, @page_3, @exercise_another_eco.page].map(&:uuid)
          page_urls = page_uuids.map{ |page_uuid| OpenStax::Cnx::V1.webview_url_for(page_uuid) }

          with_rows_from_csv("by_exercise") do |rows|
            headers = rows.first
            value_rows = rows[1..-1]
            value_rows.each do |values|
              data = Hash[headers.zip(values)]

              expect(data["Exercise Number"]).to be_in exercise_numbers.map(&:to_s)
              expect(data["Exercise Number URL"]).to be_in exercise_urls
              expect(data["# Exclusions"]).to eq "1"
              data["CNX Section UUID(s)"].split(", ").each do |page_uuid|
                expect(page_uuid).to be_in page_uuids
              end
              data["CNX Section UUID(s) URLs"].split(", ").each do |page_url|
                expect(page_url).to be_in page_urls
              end
            end
          end
        end

        it 'uploads the exported data to owncloud' do
          file_regex_string = 'excluded_exercises_stats_by_exercise_\d+T\d+Z.csv'
          webdav_url_regex = Regexp.new "#{described_class::WEBDAV_BASE_URL}/#{file_regex_string}"

          # We simply test that the call to HTTParty is made properly
          expect(HTTParty).to receive(:put).with(
            webdav_url_regex,
            basic_auth: { username: a_kind_of(String).or(be_nil),
                          password: a_kind_of(String).or(be_nil) },
            body_stream: a_kind_of(File),
            headers: { 'Transfer-Encoding' => 'chunked' }
          ).and_return OpenStruct.new(success?: true)

          described_class.call(upload_by_exercise_to_owncloud: true)
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
    filepath = routine.send "filepath_#{by_type}".to_sym
    expect(File.exist?(filepath)).to be true
    expect(filepath.ends_with? '.csv').to be true
    rows = CSV.read(filepath)
    block.call(rows)
  end

  by_course = by_type == "by_course"
  by_exercise = by_type == "by_exercise"
  described_class.call(
    upload_by_course_to_owncloud: by_course, upload_by_exercise_to_owncloud: by_exercise
  )
end
