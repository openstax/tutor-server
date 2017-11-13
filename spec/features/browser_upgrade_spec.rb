# coding: utf-8
require 'rails_helper'

RSpec.feature 'Browser upgrade' do
    context 'with old browser' do
      scenario 'not logged in' do
        visit '/'
        expect(current_path).to eq(browser_upgrade_path)
        expect(page).to have_content 'browser isn’t supported'
      end
    end
end
