require 'rails_helper'

RSpec.shared_examples 'a biglearn sparfa client' do
  let(:configuration) { OpenStax::Biglearn::Sparfa.configuration }
  subject(:client)    { described_class.new(configuration) }

  before(:all) do
    @ecosystem_matrix_uuid = SecureRandom.uuid
    @student = FactoryBot.create :course_membership_student
    @responded_before = Time.current.iso8601
    # When re-recording the cassettes, set the ecosystem matrix and student
    # uuids to values that exist in biglearn-sparfa (and save the records)
  end

  when_tagged_with_vcr = { vcr: ->(v) { !!v } }

  before(:all, when_tagged_with_vcr) do
    VCR.configure do |config|
      config.ignore_localhost = false
      config.define_cassette_placeholder('<ECOSYSTEM MATRIX UUID>') { @ecosystem_matrix_uuid }
      config.define_cassette_placeholder('<STUDENT UUID>'         ) { @student.uuid          }
      config.define_cassette_placeholder('<RESPONDED BEFORE>'     ) { @responded_before      }
    end
  end

  after(:all, when_tagged_with_vcr) { VCR.configuration.ignore_localhost = true }

  context '#fetch_ecosystem_matrices' do
    before(:all) do
      @requests = [
        { ecosystem_matrix_uuid: @ecosystem_matrix_uuid },
        {
          ecosystem_matrix_uuid: @ecosystem_matrix_uuid,
          students: [ @student ],
          responded_before: @responded_before
        }
      ]
      @request_uuids = @requests.map { SecureRandom.uuid }
    end

    before(:all, when_tagged_with_vcr) do
      VCR.configure do |config|
        @request_uuids.each_with_index do |request_uuid, request_index|
          config.define_cassette_placeholder(
            "<fetch_ecosystem_matrices REQUEST #{request_index + 1} UUID>"
          ) { request_uuid }
        end
      end
    end

    it 'returns the expected response for the request' do
      requests = @requests.each_with_index.map do |request, index|
        request.merge(request_uuid: @request_uuids[index])
      end

      expected_responses = requests.map do |request|
        request.slice(:request_uuid, :ecosystem_matrix_uuid).merge(
          responded_before: request[:responded_before],
          ecosystem_uuid: kind_of(String),
          L_ids: [ @student.uuid ],
          Q_ids: kind_of(Array),
          C_ids: kind_of(Array),
          d_data: kind_of(Array),
          W_data: kind_of(Array),
          W_row: kind_of(Array),
          W_col: kind_of(Array),
          H_mask_data: kind_of(Array),
          H_mask_row: kind_of(Array),
          H_mask_col: kind_of(Array),
          G_data: kind_of(Array),
          G_row: kind_of(Array),
          G_col: kind_of(Array),
          G_mask_data: kind_of(Array),
          G_mask_row: kind_of(Array),
          G_mask_col: kind_of(Array),
          U_data: kind_of(Array),
          U_row: kind_of(Array),
          U_col: kind_of(Array)
        )
      end

      actual_responses = client.fetch_ecosystem_matrices requests
      responses_without_superseded = actual_responses.map do |response|
        response.except :superseded_at
      end

      expect(responses_without_superseded).to match_array(expected_responses)
      actual_responses.each do |response|
        expect(response[:superseded_at]).to be_nil.or(be_kind_of(String))
      end
    end
  end
end
