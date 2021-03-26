# coding: utf-8
require 'rails_helper'

RSpec.feature 'Homepage' do
  context 'user' do
    scenario 'not logged in' do
      visit '/?ignore_browser'
      expect(current_path).to eq('/')

      expect(page).to have_content 'Rice University'
    end
  end
end
