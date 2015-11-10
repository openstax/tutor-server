
module ActiveForce

  class << self

    # Use a lazy setting of the client so that migrations etc are in place
    # to allow the RealClient to be successfully instantiated.
    alias_method :original_sfdc_client, :sfdc_client
    def sfdc_client
      if !original_sfdc_client.is_a?(Salesforce::Remote::RealClient)
        self.sfdc_client = Salesforce::Remote::RealClient.new
      end
      original_sfdc_client
    end
  end

end
