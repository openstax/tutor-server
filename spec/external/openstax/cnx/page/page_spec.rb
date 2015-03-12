require 'rails_helper'

# module OpenStax
#   module Cnx
#     module V1
#       class ReadingFragment
#       end

#       class ExerciseFragment
#       end

#       class VideoFragment
#       end

#       class SimulationFragment
#       end
#     end
#   end
# end

describe OpenStax::Cnx::V1::Page do
  context "some context" do
    let!(:bio_book_id)          { '185cbf87-c72e-48f5-b51e-f14f21b5eabd@9.80' }
    let!(:concepts_bio_book_id) { 'b3c1e1d2-839c-42b0-a314-e119a8aafbdd@8.53' }
    let!(:test_book_id)         { '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@1.4' }
    let!(:statistics_book_id)   { '30189442-6998-4686-ac05-ed152b91b9de@17.42' }
    let!(:us_history_book_id)   { 'a7ba2fb8-8925-4987-b182-5f4429d48daa@3.7' }
    let!(:macro_econ_book_id)   { '4061c832-098e-4b3c-a1d9-7eb593a2cb31@10.58' }
    # let!(:_book_id)       { '' }
    # let!(:_book_id)       { '' }
    let!(:book_ids) { [test_book_id, bio_book_id, concepts_bio_book_id,
                       statistics_book_id, us_history_book_id, macro_econ_book_id]}

    it "wraps the json" do
      binding.pry
      [test_book_id].each do |book_id|
        puts "="*40
        puts OpenStax::Cnx::V1::Book.fetch(book_id).to_s
      end
    end

  end
end
