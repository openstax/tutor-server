class Api::V1::TermsController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Info about which terms have been signed and endpoints for signing'
    description <<-EOS
    EOS
  end

  api :GET, '/terms', 'Returns info on terms applicable to current user'
  description <<-EOS
    Output looks like:

    ```
    [
      {
        id: 42,
        name: "general_terms_of_use",
        title: "Terms of Use",
        content: "bunch of HTML",
        version: 2,
        is_signed: false,
        has_signed_before: true,
        is_proxy_signed: false
      },
      ...
    ]
    ```
  EOS
  def index
    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    else
      respond_to do |format|
        format.json { render json: GetUserTermsInfos[current_human_user].to_json }
      end
    end
  end

  api :PUT, '/terms/:ids', 'Signs the identified terms for the current user'
  description <<-EOS
    :ids should be a comma-separated list of contract IDs that the user signed

    403 if forbidden
    400 with message if no IDs provided
    422 with message if can't find terms or other signature error
    200 if all good (repeat signatures are ok)
  EOS
  def sign
    return head :forbidden if current_human_user.nil? || current_human_user.is_anonymous?
    return render_api_errors(:terms_ids_missing, :bad_request) if params[:ids].blank?

    params[:ids].split(',').map(&:strip).each do |id|
      signature =
        begin
          FinePrint.sign_contract(current_human_user, id)
        rescue ActiveRecord::RecordNotFound
          return render_api_errors("Terms with ID #{id} not found")
        end

      # Go to next if already signed
      next if signature.errors.get_type(:contract_id) == [:taken]

      return render_api_errors(signature.errors) if signature.errors.any?
    end

    head :ok
  end

end
