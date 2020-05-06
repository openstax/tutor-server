require 'rails_helper'

RSpec.describe Admin::TagsController, type: :request do
  let(:admin)  { FactoryBot.create(:user_profile, :administrator) }

  let!(:tag_1) { FactoryBot.create :content_tag, value: 'k12phys-ch04-ex003' }
  let!(:tag_2) { FactoryBot.create :content_tag, value: 'k12phys-ch04-s03-lo01' }
  let!(:tag_3) { FactoryBot.create :content_tag, value: 'ost-tag-teks-112-39-c-4d' }

  before { sign_in! admin }

  context 'GET #index' do
    it 'does not list tags' do
      get admin_tags_url
      expect(assigns[:tags]).to be_nil
    end

    it 'returns a list of tags that matches tag value' do
      get admin_tags_url, params: { query: 'k12phys' }

      expect(assigns[:tags].order(:id)).to eq [tag_1, tag_2]
    end

    it 'returns nothing if there are no matches' do
      get admin_tags_url, params: { query: 'time-short' }

      expect(assigns[:tags]).to eq []
    end
  end

  context 'PUT #update' do
    it 'updates the name, description and visible flag of the tag' do
      put admin_tag_url(tag_1.id), params: {
        tag: {
          name: 'k12 physics chapter 4 exercise 3',
          description: 'Student should be able to do this exercise',
          value: 'immutable',
          visible: '0'
        }
      }

      tag_1.reload
      expect(tag_1.value).to eq 'k12phys-ch04-ex003'
      expect(tag_1.name).to eq 'k12 physics chapter 4 exercise 3'
      expect(tag_1.description).to eq 'Student should be able to do this exercise'
      expect(tag_1.visible).to be false
    end
  end

  context 'disallowing baddies' do
    it '#GET disallows unauthenticated visitors' do
      sign_out!

      get admin_tags_url
      expect(response).not_to be_successful
    end

    it '#PUT disallows unauthenticated visitors' do
      sign_out!

      put admin_tag_url(tag_1.id)
      expect(response).not_to be_successful
    end

    it 'disallows non-admin authenticated visitors' do
      sign_in! FactoryBot.create(:user_profile)

      expect { get admin_tags_url }.to raise_error(SecurityTransgression)
      expect { put admin_tag_url(tag_1.id) }.to raise_error(SecurityTransgression)
    end
  end
end
