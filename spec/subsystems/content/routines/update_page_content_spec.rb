require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::UpdatePageContent, type: :routine do

  before(:all) do
    cnx_page_1 = OpenStax::Cnx::V1::Page.new(
      id: '102e9604-daa7-4a09-9f9e-232251d1a4ee@7',
      title: 'Physical Quantities and Units'
    )
    cnx_page_2 = OpenStax::Cnx::V1::Page.new(
      id: '127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
      title: "Introduction to Electric Current, Resistance, and Ohm's Law"
    )

    chapter_1 = FactoryBot.create :content_chapter, book_location: [1]
    @book = chapter_1.book
    chapter_20 = FactoryBot.create :content_chapter, book: @book, book_location: [20]

    @pages = OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents/') do
      VCR.use_cassette("Content_Routines_UpdatePageContent/with_book", VCR_OPTS) do
        [
          Content::Routines::ImportPage[
            cnx_page: cnx_page_1, chapter: chapter_1, book_location: [1, 2]
          ],
          Content::Routines::ImportPage[
            cnx_page: cnx_page_2, chapter: chapter_20, book_location: [20, 0]
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
                ] + before_hrefs[1..-1]
              end

              it 'updates page links in content to relative urls if the pages are in same book' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each_with_index do |value, index|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq before_hrefs[index]
                end

                described_class.call(book: @book, pages: @pages)
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
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

                described_class.call(book: @book, pages: @pages)
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
            let(:book_after_href) { "/books/#{@book.id}" }

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

              described_class.call(book: @book, pages: @pages)
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
                ] + before_hrefs[1..-1]
              end

              it 'updates page links in content to relative urls if the pages are in same book' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each_with_index do |value, index|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq before_hrefs[index]
                end

                described_class.call(book: @book, pages: @pages)
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
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

                described_class.call(book: @book, pages: @pages)
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
            let(:book_after_href) { "/books/#{@book.id}" }

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

              described_class.call(book: @book, pages: @pages)
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
                ] + before_hrefs[1..-1]
              end

              it 'updates page links in content to relative urls if the pages are in same book' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each_with_index do |value, index|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq before_hrefs[index]
                end

                described_class.call(book: @book, pages: @pages)
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
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

                described_class.call(book: @book, pages: @pages)
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
            let(:book_after_href) { "/books/#{@book.id}" }

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

              described_class.call(book: @book, pages: @pages)
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
                  "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}"
                ] + before_hrefs[1..-1]
              end

              it 'updates page links in content to relative urls if the pages are in same book' do
                doc = Nokogiri::HTML(@page_1.content)

                link_text.each_with_index do |value, index|
                  link = doc.xpath("//a[text()=\"#{value}\"]").first
                  expect(link.attribute('href').value).to eq before_hrefs[index]
                end

                described_class.call(book: @book, pages: @pages)
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
                [ "/books/#{@book.id}/section/#{@page_2.book_location.reject(&:zero?).join('.')}" ] +
                composite_before_hrefs[1..-1]
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

                described_class.call(book: @book, pages: @pages)
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
            let(:book_after_href) { "/books/#{@book.id}" }

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

              described_class.call(book: @book, pages: @pages)
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
