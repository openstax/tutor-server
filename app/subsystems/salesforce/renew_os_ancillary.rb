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
        term_year: renew_for_term_year
      }

      target_opportunities = Salesforce::Remote::Opportunity.where(target_opportunity_criteria).all

      if target_opportunities.size > 1
        raise OsAncillaryRenewalError, "Too many opportunities matching #{target_opportunity_criteria}"
      elsif target_opportunities.size == 0
        raise OsAncillaryRenewalError, "No opportunities matching #{target_opportunity_criteria}"
      end

      target_opportunity = target_opportunities.first

      based_on_product =
        case based_on
        when Salesforce::Remote::OsAncillary
          based_on.product
        when Salesforce::Remote::ClassSize
          "Concept Coach"
        end

      os_ancillary_attributes = {
        opportunity_id: target_opportunity.id,
        product: based_on_product
      }

      existing_os_ancillary = Salesforce::Remote::OsAncillary.where(os_ancillary_attributes).first
      return existing_os_ancillary if existing_os_ancillary.present?

      new_os_ancillary = Salesforce::Remote::OsAncillary.new(
        os_ancillary_attributes.merge(
          course_id: based_on.course_id,
          status: Remote::OsAncillary::STATUS_APPROVED,
          error: nil
        )
      )

      if !new_os_ancillary.save
        raise OsAncillaryRenewalError,
              "Could not save renewed OS Ancillary: " \
              "#{new_os_ancillary.errors.full_messages.join(', ')}"
      end

      new_os_ancillary
    end
  end

  class OsAncillaryRenewalError < StandardError; end
end
