module Salesforce
  class RenewOsAncillary

    # TODO handle exceptions in caller, email devs / SF devs

    def self.call(original_os_ancillary:)
      # Would be nice to have preloaded opportunity, but have had problems making it work
      original_opportunity = original_os_ancillary.opportunity

      # We want to hang a new OSA off of a similar opportunity for the next TermYear
      target_opportunity_criteria = {
        contact_id: original_opportunity.contact_id,
        book_name: original_opportunity.book_name,
        term_year: next_term_year(original_opportunity.term_year)
      }

      target_opportunities = Salesforce::Remote::Opportunity.where(target_opportunity_criteria).all

      if target_opportunities.size > 1
        raise OsAncillaryRenewalError, "Too many opportunities matching #{target_opportunity_criteria}"
      elsif target_opportunities.size == 0
        raise OsAncillaryRenewalError, "No opportunities matching #{target_opportunity_criteria}"
      end

      target_opportunity = target_opportunities.first

      os_ancillary_attributes = {
        opportunity_id: target_opportunity.id,
        product: original_os_ancillary.product
      }

      existing_os_ancillary = Salesforce::Remote::OsAncillary.where(os_ancillary_attributes).first
      return existing_os_ancillary if existing_os_ancillary.present?

      new_os_ancillary = Salesforce::Remote::OsAncillary.new(
        os_ancillary_attributes.merge(
          course_id: original_os_ancillary.course_id,
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

    def self.next_term_year(from)
      from.match(/20(\d\d) - (\d\d) (\w+)/)

      $3 == 'Fall' ?
        "20#{$1} - #{$2} Spring" :
        "20#{$1.to_i + 1} - #{$2.to_i + 1} Fall"
    end
  end

  class OsAncillaryRenewalError < StandardError; end
end
