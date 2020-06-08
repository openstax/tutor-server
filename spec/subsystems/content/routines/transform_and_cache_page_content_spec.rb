require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::TransformAndCachePageContent, type: :routine, vcr: VCR_OPTS do
  context 'with real content' do
    before(:all) do
      cnx_page_1 = OpenStax::Cnx::V1::Page.new(
        id: '102e9604-daa7-4a09-9f9e-232251d1a4ee@7',
        title: 'Physical Quantities and Units'
      )
      cnx_page_2 = OpenStax::Cnx::V1::Page.new(
        id: '127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
        title: "Introduction to Electric Current, Resistance, and Ohm's Law"
      )

      @book = FactoryBot.create :content_book

      @pages = OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents/') do
        VCR.use_cassette("Content_Routines_TransformAndCachePageContent/with_book", VCR_OPTS) do
          [
            Content::Routines::ImportPage[
              cnx_page: cnx_page_1,
              book: @book,
              book_indices: [1, 2],
              parent_book_part_uuid: SecureRandom.uuid
            ],
            Content::Routines::ImportPage[
              cnx_page: cnx_page_2,
              book: @book,
              book_indices: [20, 0],
              parent_book_part_uuid: SecureRandom.uuid
            ]
          ]
        end
      end
      @page_1 = @pages.first
      @page_2 = @pages.second
    end

    ORIGINAL_HREFS = [
      'https://cnx.org/contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
      'https://cnx.org/contents/4bba6a1c-a0e6-45c0-988c-0d5c23425670@7',
      'https://cnx.org/contents/aaf30a54-a356-4c5f-8c0d-2f55e4d20556@3'
    ]

    let(:link_text) do
      [
        "Introduction to Electric Current, Resistance, and Ohm's Law",
        'Accuracy, Precision, and Significant Figures',
        'Appendix A'
      ]
    end

    before { @page_1.reload }

    [
      'http://cnx.org', 'http://archive.cnx.org', 'https://cnx.org', 'https://archive.cnx.org', ''
    ].each do |link_prefix|
      context "#{link_prefix.blank? ? 'no' : link_prefix} link prefix" do
        before(:all) do
          DatabaseCleaner.start

          @link_prefix_hrefs = ORIGINAL_HREFS.map do |original_href|
            original_href.sub 'https://cnx.org', link_prefix
          end
          @pages.each do |page|
            page.url.sub! 'https://cnx.org', link_prefix

            ORIGINAL_HREFS.each_with_index do |original_href, index|
              page.content.gsub! original_href, @link_prefix_hrefs[index]
            end

            page.save!
          end
        end
        after(:all)  do
          DatabaseCleaner.clean

          @pages.each(&:reload)
        end

        context 'with simple ToC urls' do
          context 'with versions' do
            let(:before_hrefs)     { @link_prefix_hrefs }

            let(:book_before_href) { "#{link_prefix}/contents/#{@book.uuid}@#{@book.version}" }

            context 'page links' do
              context 'simple' do
                let(:after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + before_hrefs[1..-1]
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq after_hrefs[index]
                  end
                end
              end

              context 'composite' do
                let(:composite_before_hrefs) do
                  before_hrefs.map do |href|
                    href.sub "#{link_prefix}/contents/", "#{book_before_href}:"
                  end
                end

                let(:composite_after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + composite_before_hrefs[1..-1]
                end

                before do
                  before_hrefs.each_with_index do |href, index|
                    @page_1.content.gsub! href, composite_before_hrefs[index]
                  end

                  @page_1.save!
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_after_hrefs[index]
                  end
                end
              end
            end

            context 'book links' do
              let(:book_after_href) { "/book/#{@book.ecosystem.id}" }

              before do
                before_hrefs.each { |href| @page_1.content.gsub! href, book_before_href }

                @page_1.save!
              end

              it 'updates links to the current book in content to relative urls' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_before_href
                end

                described_class.call(book: @book)
                @pages.each(&:save!)

                doc = Nokogiri::HTML(@page_1.reload.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_after_href
                end
              end
            end
          end

          context 'without versions' do
            before(:all) do
              DatabaseCleaner.start

              @before_hrefs = @link_prefix_hrefs.map do |link_prefix_href|
                link_prefix_href.split('@').first
              end
              @pages.each do |page|
                page.reload

                @link_prefix_hrefs.each_with_index do |link_prefix_href, index|
                  page.content.gsub! link_prefix_href, @before_hrefs[index]
                end

                page.save!
              end
            end
            after(:all)  do
              DatabaseCleaner.clean

              @pages.each(&:reload)
            end

            let(:before_hrefs)     { @before_hrefs }

            let(:book_before_href) { "#{link_prefix}/contents/#{@book.uuid}" }

            context 'page links' do
              context 'simple' do
                let(:after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + before_hrefs[1..-1]
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq after_hrefs[index]
                  end
                end
              end

              context 'composite' do
                let(:composite_before_hrefs) do
                  before_hrefs.map do |href|
                    href.sub "#{link_prefix}/contents/", "#{book_before_href}:"
                  end
                end

                let(:composite_after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + composite_before_hrefs[1..-1]
                end

                before do
                  before_hrefs.each_with_index do |href, index|
                    @page_1.content.gsub! href, composite_before_hrefs[index]
                  end

                  @page_1.save!
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_after_hrefs[index]
                  end
                end
              end
            end

            context 'book links' do
              let(:book_after_href) { "/book/#{@book.ecosystem.id}" }

              before do
                before_hrefs.each { |href| @page_1.content.gsub! href, book_before_href }

                @page_1.save!
              end

              it 'updates links to the current book in content to relative urls' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_before_href
                end

                described_class.call(book: @book)
                @pages.each(&:save!)

                doc = Nokogiri::HTML(@page_1.reload.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_after_href
                end
              end
            end
          end
        end

        context 'with composite ToC urls' do
          before(:all) do
            DatabaseCleaner.start

            @pages.each do |page|
              page.url.sub! "#{page.uuid}@#{page.version}",
                            "#{@book.uuid}@#{@book.version}:#{page.uuid}@#{page.version}"

              page.save!
            end
          end
          after(:all)  do
            DatabaseCleaner.clean

            @pages.each(&:reload)
          end

          context 'with versions' do
            let(:before_hrefs)     { @link_prefix_hrefs }

            let(:book_before_href) { "#{link_prefix}/contents/#{@book.uuid}@#{@book.version}" }

            context 'page links' do
              context 'simple' do
                let(:after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + before_hrefs[1..-1]
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq after_hrefs[index]
                  end
                end
              end

              context 'composite' do
                let(:composite_before_hrefs) do
                  before_hrefs.map do |href|
                    href.sub "#{link_prefix}/contents/", "#{book_before_href}:"
                  end
                end

                let(:composite_after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + composite_before_hrefs[1..-1]
                end

                before do
                  before_hrefs.each_with_index do |href, index|
                    @page_1.content.gsub! href, composite_before_hrefs[index]
                  end

                  @page_1.save!
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_after_hrefs[index]
                  end
                end
              end
            end

            context 'book links' do
              let(:book_after_href) { "/book/#{@book.ecosystem.id}" }

              before do
                before_hrefs.each { |href| @page_1.content.gsub! href, book_before_href }

                @page_1.save!
              end

              it 'updates links to the current book in content to relative urls' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_before_href
                end

                described_class.call(book: @book)
                @pages.each(&:save!)

                doc = Nokogiri::HTML(@page_1.reload.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_after_href
                end
              end
            end
          end

          context 'without versions' do
            before(:all) do
              DatabaseCleaner.start

              @before_hrefs = @link_prefix_hrefs.map do |link_prefix_href|
                link_prefix_href.split('@').first
              end
              @pages.each do |page|
                page.reload

                @link_prefix_hrefs.each_with_index do |link_prefix_href, index|
                  page.content.gsub! link_prefix_href, @before_hrefs[index]
                end

                page.save!
              end
            end
            after(:all)  do
              DatabaseCleaner.clean

              @pages.each(&:reload)
            end

            let(:before_hrefs)     { @before_hrefs }

            let(:book_before_href) { "#{link_prefix}/contents/#{@book.uuid}" }

            context 'page links' do
              context 'simple' do
                let(:after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + before_hrefs[1..-1]
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq after_hrefs[index]
                  end
                end
              end

              context 'composite' do
                let(:composite_before_hrefs) do
                  before_hrefs.map do |href|
                    href.sub "#{link_prefix}/contents/", "#{book_before_href}:"
                  end
                end

                let(:composite_after_hrefs) do
                  [
                    "/book/#{@book.ecosystem.id}/page/#{@page_2.id}"
                  ] + composite_before_hrefs[1..-1]
                end

                before do
                  before_hrefs.each_with_index do |href, index|
                    @page_1.content.gsub! href, composite_before_hrefs[index]
                  end

                  @page_1.save!
                end

                it 'updates page links in content to relative urls if the pages are in same book' do
                  doc = Nokogiri::HTML(@page_1.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_before_hrefs[index]
                  end

                  described_class.call(book: @book)
                  @pages.each(&:save!)

                  doc = Nokogiri::HTML(@page_1.reload.content)

                  link_text.each_with_index do |value, index|
                    link = doc.xpath("//a[text()=\"#{value}\"]").first
                    expect(link.attribute('href').value).to eq composite_after_hrefs[index]
                  end
                end
              end
            end

            context 'book links' do
              let(:book_after_href) { "/book/#{@book.ecosystem.id}" }

              before do
                before_hrefs.each { |href| @page_1.content.gsub! href, book_before_href }

                @page_1.save!
              end

              it 'updates links to the current book in content to relative urls' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_before_href
                end

                described_class.call(book: @book)
                @pages.each(&:save!)

                doc = Nokogiri::HTML(@page_1.reload.content)

                link_text.each do |value|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq book_after_href
                end
              end
            end
          end
        end
      end
    end
  end

  context 'with custom tags' do
    let(:exercise_tags_array) do
      [
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509'],
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509',
         'context-cnxfeature:fs-idp56122560'],
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509',
         'context-cnxfeature:fs-idp56122560', 'requires-context:y'],
        ['k12phys-ch03-s01-lo02', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509',
         'context-cnxfeature:fs-idp42721584', 'requires-context:true'],
      ]
    end

    let(:wrappers) do
      exercise_tags_array.each_with_index.map do |exercise_tags, index|
        options = { number: index + 1, version: 1, tags: exercise_tags }
        content_hash = OpenStax::Exercises::V1::FakeClient.new_exercise_hash(options)

        OpenStax::Exercises::V1::Exercise.new(content: content_hash.to_json)
      end
    end

    let(:expected_context_node_ids) do
      [nil, nil, 'fs-idp56122560', 'fs-idp42721584']
    end

    before(:all) do
      @book = FactoryBot.create :content_book

      @ecosystem = @book.ecosystem

      cnx_page = OpenStax::Cnx::V1::Page.new(
        id: '0e58aa87-2e09-40a7-8bf3-269b2fa16509', title: 'Acceleration'
      )

      @page = VCR.use_cassette('Content_Routines_ImportExercises/with_custom_tags', VCR_OPTS) do
        Content::Routines::ImportPage[
          cnx_page: cnx_page,
          book: @book,
          book_indices: [3, 1]
        ]
      end
    end

    before do
      expect(OpenStax::Exercises::V1).to receive(:exercises).once do |_, &block|
        block.call(wrappers)
      end

      Content::Routines::ImportExercises.call(
        ecosystem: @ecosystem,
        page: @page,
        query_hash: { tag: ['k12phys-ch03-s01-lo01', 'k12phys-ch03-s01-lo02'] }
      )

      Content::Routines::PopulateExercisePools.call book: @book
    end

    it 'assigns context for exercises that require context' do
      imported_exercises = @ecosystem.exercises.order(:number).to_a
      imported_exercises.each { |ex| expect(ex.context).to be_nil }

      expect { described_class.call book: @book }.not_to change { Content::Models::Exercise.count }

      imported_exercises.map(&:reload).each_with_index do |exercise, index|
        expected_context_node_id = expected_context_node_ids[index]

        if expected_context_node_id.nil?
          expect(exercise.context).to be_nil
        else
          context_node = Nokogiri::HTML.fragment(exercise.context).children.first
          expect(context_node.attr('id')).to eq expected_context_node_id
        end
      end
    end
  end

  context 'with an exercise that requires context from a Section Summary' do
    let(:manifest_path)   { 'spec/fixtures/manifests/Section Summary Context Exercise.yml' }
    let(:manifest_string) { File.read manifest_path }

    it "sets the exercise's context from the Section Summary"  do
      ecosystem = ImportEcosystemManifest[manifest: manifest_string]
      exercise = ecosystem.exercises.first
      expect(exercise.context).not_to be_blank
    end
  end
end
