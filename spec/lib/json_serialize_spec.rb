require 'rails_helper'

RSpec.describe JsonSerialize, type: :lib do
  context 'serializes and deserializes' do
    context 'single' do
      it 'hashes' do
        instance = FactoryGirl.build :tasks_task
        instance.spy = {}
        expect(instance.spy).to eq({})

        instance.spy[:testing] = [1, 2, 3]
        expect(instance.spy).to eq({ testing: [1, 2, 3] })

        instance.save!
        expect(instance.spy).to eq({ testing: [1, 2, 3] })

        instance.reload
        expect(instance.spy).to eq({ 'testing' => [1, 2, 3] })

        instance.spy[:test] = ['a', 'b', 'c']
        expect(instance.spy).to eq({ 'testing' => [1, 2, 3], test: ['a', 'b', 'c'] })

        instance.save!
        expect(instance.spy).to eq({ 'testing' => [1, 2, 3], test: ['a', 'b', 'c'] })

        instance.reload
        expect(instance.spy).to eq({ 'testing' => [1, 2, 3], 'test' => ['a', 'b', 'c'] })

        instance.spy = {}
        expect(instance.spy).to eq({})

        instance.save!
        expect(instance.spy).to eq({})

        instance.reload
        expect(instance.spy).to eq({})
      end

      # Not used by any model in tutor-server
      xit 'arrays' do
      end
    end

    context 'arrays of' do
      it 'integers' do
        instance = FactoryGirl.build :tasks_tasked_reading
        instance.book_location = []
        expect(instance.book_location).to eq []

        instance.book_location << 1
        expect(instance.book_location).to eq [1]

        instance.save!
        expect(instance.book_location).to eq [1]

        instance.reload
        expect(instance.book_location).to eq [1]

        instance.book_location << 2
        expect(instance.book_location).to eq [1, 2]

        instance.save!
        expect(instance.book_location).to eq [1, 2]

        instance.reload
        expect(instance.book_location).to eq [1, 2]

        instance.book_location = []
        expect(instance.book_location).to eq []

        instance.save!
        expect(instance.book_location).to eq []

        instance.reload
        expect(instance.book_location).to eq []
      end

      # Not used by any model in tutor-server
      xit 'floats' do
      end

      it 'strings' do
        instance = Legal::Models::TargetedContract.new(
          target_gid: '', target_name: '', contract_name: ''
        )
        expect(instance.masked_contract_names).to eq []

        instance.masked_contract_names << 'test'
        expect(instance.masked_contract_names).to eq ['test']

        instance.save!
        expect(instance.masked_contract_names).to eq ['test']

        instance.reload
        expect(instance.masked_contract_names).to eq ['test']

        instance.masked_contract_names << 'testing'
        expect(instance.masked_contract_names).to eq ['test', 'testing']

        instance.save!
        expect(instance.masked_contract_names).to eq ['test', 'testing']

        instance.reload
        expect(instance.masked_contract_names).to eq ['test', 'testing']

        instance.masked_contract_names = []
        expect(instance.masked_contract_names).to eq []

        instance.save!
        expect(instance.masked_contract_names).to eq []

        instance.reload
        expect(instance.masked_contract_names).to eq []
      end

      it 'hashes' do
        instance = FactoryGirl.create :content_book,
                                      reading_processing_instructions: [{ testing: [1, 2, 3] }]
        expect(instance.reading_processing_instructions).to eq [{ 'testing' => [1, 2, 3] }]

        instance.save!
        expect(instance.reading_processing_instructions).to eq [{ 'testing' => [1, 2, 3] }]

        instance.reload
        expect(instance.reading_processing_instructions).to eq [{ 'testing' => [1, 2, 3] }]

        instance.reading_processing_instructions << { test: ['a', 'b', 'c'] }
        expect(instance.reading_processing_instructions).to eq [{ 'testing' => [1, 2, 3] },
                                                                { test: ['a', 'b', 'c'] }]

        instance.save!
        expect(instance.reading_processing_instructions).to eq [{ 'testing' => [1, 2, 3] },
                                                                { test: ['a', 'b', 'c'] }]

        instance.reload
        expect(instance.reading_processing_instructions).to eq [{ 'testing' => [1, 2, 3] },
                                                                { 'test' => ['a', 'b', 'c'] }]

        instance.reading_processing_instructions = []
        expect(instance.reading_processing_instructions).to eq []

        instance.save!
        expect(instance.reading_processing_instructions).to eq []

        instance.reload
        expect(instance.reading_processing_instructions).to eq []
      end

      # Not used by any model in tutor-server
      xit 'arrays' do
      end
    end
  end
end
