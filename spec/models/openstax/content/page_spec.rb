# coding: utf-8
require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Content::Page, type: :external, vcr: VCR_OPTS do
  context 'with parts of college phys' do
    before(:all) do
      @hashes_with_pages = VCR.use_cassette(
        'OpenStax_Content_Page/with_mini_ecosystem_pages', VCR_OPTS
      ) do
        MINI_ECOSYSTEM_OPENSTAX_PAGE_HASHES.map do |hash|
          ox_page = OpenStax::Content::Page.new(
            book: MINI_ECOSYSTEM_OPENSTAX_BOOK, hash: hash.deep_stringify_keys
          )

          ox_page.full_hash

          [ hash, ox_page ]
        end
      end
    end

    it 'provides info about the page for the given hash' do
      @hashes_with_pages.each do |hash, page|
        expect(page.uuid).to eq hash[:id]
        expect(page.url).to include(hash[:id])
        expect(page.title).to eq page.parsed_title.text
        expect(page.full_hash).not_to be_empty
        expect(page.content).not_to be_blank
        expect(page.doc).not_to be_nil
        expect(page.root).not_to be_nil
        expect(page.los).not_to be_nil
        expect(page.tags).not_to be_nil
      end
    end

    it "converts links to sims to iframes, links to exercises to absolute URLs" do
      @hashes_with_pages.each do |hash, page|
        page.convert_content!

        doc = page.doc

        doc.css('[href]').each do |tag|
          uri = Addressable::URI.parse(tag.attributes['href'].value)
          expect(uri.path).not_to start_with('../resources')
          expect(uri.path).not_to start_with('#ost/api/ex')
          expect(uri.path).not_to start_with('#exercise')
        end
      end

      expect(
        @hashes_with_pages.any? { |_, page| page.doc.at_css('[src^="../resources"]') }
      ).to eq true
    end

    it "extracts the LO's from the page" do
      @hashes_with_pages.each do |hash, page|
        expect(page.los).to eq []
      end
    end

    it 'extracts tag names and descriptions from the page' do
      @hashes_with_pages.each do |hash, page|
        expect(Set.new page.tags).to eq Set.new([{ :value=>"context-cnxmod:#{hash[:id]}", :type=>:cnxmod }])
      end
    end
  end

  context 'parsing html titles' do
    it 'extracts os-number and retains all HTML' do
      html = '<span class="os-number"><span class="os-part-text">Unit </span>1.42</span><span class="os-divider"> </span><span data-type="" itemprop="" class="os-text"><i>The Florentine Codex</i>, c. 1585</span>'
      page = OpenStax::Content::Page.new(
        hash: { 'id' => '123', 'title' => html }
      )
      expect(page.book_location).to eq [1, 42]
      expect(page.title).to eq html
    end

    it 'leaves book_location blank if not present' do
      page = OpenStax::Content::Page.new(
        hash: { 'id' => '123', 'title' => '<span class="os-text">Review Questions</span>' }
      )
      expect(page.book_location).to eq []
    end

    it 'continues to function for plain text titles' do
      page = OpenStax::Content::Page.new(
        hash: { 'id' => '123', 'title' => 'Hello World!' }
      )
      expect(page.book_location).to be_empty
      expect(page.title).to eq 'Hello World!'
    end
  end
end
