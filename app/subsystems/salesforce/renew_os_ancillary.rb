module Salesforce
  class RenewOsAncillary

    # `based_on` can either be an `OsAncillary` or the legacy `ClassSize`
    def self.call(based_on:, renew_for_term_year:)

      # Would be nice to have preloaded opportunity, but have had problems making it work
      based_on_opportunity = based_on.opportunity

      # We want to hang a new OSA off of a similar opportunity for the next TermYear
      target_opportunity_criteria = {
        contact_id: based_on_opportunity.contact_id,
        book_name: based_on_opportunity.book_name,
        term_year: renew_for_term_year.to_s
      }

      target_opportunities = Salesforce::Remote::Opportunity.where(target_opportunity_criteria).to_a

      if target_opportunities.size > 1
        raise OsAncillaryRenewalError, "Too many opportunities matching #{target_opportunity_criteria}"
      elsif target_opportunities.size == 0
        raise OsAncillaryRenewalError, "No opportunities matching #{target_opportunity_criteria}"
      end

      target_opportunity = target_opportunities.first

      os_ancillary_attributes = {
        opportunity_id: target_opportunity.id,
        product: based_on.product
      }

      existing_os_ancillary = Salesforce::Remote::OsAncillary.where(os_ancillary_attributes).first
      return existing_os_ancillary if existing_os_ancillary.present?

      new_os_ancillary = Salesforce::Remote::OsAncillary.new(
        os_ancillary_attributes.merge(
          course_id: based_on.course_id,
          status: Remote::OsAncillary::STATUS_APPROVED,
          error: nil,
          teacher_join_url: based_on.teacher_join_url
        )
      )

      if !new_os_ancillary.save
        raise OsAncillaryRenewalError,
              "Could not save renewed OS Ancillary: " \
              "#{new_os_ancillary.errors.full_messages.join(', ')}"
      end

      # Values in the OSA that are derived from other places in SF, e.g. `TermYear`,
      # cannot be set when creating the record above.  Instead of manually setting them
      # here, just reload the object from SF so that we know any derived fields are
      # populated.
      new_os_ancillary.reload
    end
  end

  class OsAncillaryRenewalError < StandardError; end
end
