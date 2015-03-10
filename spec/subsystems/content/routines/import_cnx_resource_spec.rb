require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportCnxResource, :type => :routine, :vcr => VCR_OPTS do

  cnx_ids = { book: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58',
              page: '092bbf0d-0729-42ce-87a6-fd96fd87a083' }

  cnx_ids.each do |name, cnx_id|
    it "returns the hash for a CNX #{name.to_s} request" do
      result = Content::ImportCnxResource.call(cnx_id)
      expect(result.errors).to be_empty
      out = result.outputs
      expect(out[:hash]).not_to be_blank
      expect(out[:url]).not_to be_blank
      expect(out[:content]).not_to be_blank
    end
  end

end
