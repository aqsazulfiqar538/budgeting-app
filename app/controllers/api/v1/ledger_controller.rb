# frozen_string_literal: true

class Api::V1::LedgerController < ApplicationController
  # GET /api/v1/ledger
  def index
    render json: LedgerService.new(current_user).summary
  end

  # GET /api/v1/ledger/:friend_id
  def show
    detail = LedgerService.new(current_user).detail(params[:id])
    if detail[:error]
      render_error(detail[:error], status: :forbidden)
    else
      render json: detail
    end
  end
end
