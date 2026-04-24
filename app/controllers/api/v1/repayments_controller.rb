class Api::V1::RepaymentsController < ApplicationController
  def settle
    repayment = find_repayment

    if repayment.settled?
      render_error("Already settled")
      return
    end

    if RepaymentSettlementService.new(repayment, current_user).call
      render json: RepaymentSerializer.new(repayment.reload).serializable_hash
    else
      render_error("Unable to settle repayment")
    end
  end

  private

  def find_repayment
    Repayment.where("from_user_id = :uid OR to_user_id = :uid", uid: current_user.id).find(params[:id])  #raise exception so it'll be handled 
  end
end
