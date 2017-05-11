require 'rails_helper'

RSpec.describe TrackTutorOnboardingEvent, type: :routine do

  context 'arrive to marketing page from pardot' do
    context 'anonymous user' do

    end

    context 'signed in' do
      context 'has salesforce contact ID' do

      end

      context 'no salesforce contact ID' do

      end
    end

    context 'teacher 1 forwards email to teacher 2 who uses same link' do
      it 'does not reuse teacher 1\'s TOA' do

      end
    end

    context '2nd arrival from same user' do
      it 'does not overwrite the first timestamp' do

      end
    end
  end


end
