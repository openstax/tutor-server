class TermsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  # Allow accessing from within iframes
  before_action :allow_iframe_access, only: [:index, :pose, :agree]

  before_action :use_openstax_logo

  def index
    @contracts = [ FinePrint.get_contract(:general_terms_of_use),
                   FinePrint.get_contract(:privacy_policy) ]
  end

  def pose
    @contract = FinePrint.get_contract(params[:id])
  end

  def agree
    signature = FinePrint.sign_contract(current_user, params[:contract_id]) if params[:i_agree]

    if signature && signature.errors.none?
      fine_print_return
    else
      @contract = FinePrint.get_contract(params[:contract_id])
      flash.now[:alert] = 'There was an error when trying to agree to these terms.'
      render 'pose'
    end
  end

  def use_openstax_logo
    @use_openstax_logo = true
  end
end
