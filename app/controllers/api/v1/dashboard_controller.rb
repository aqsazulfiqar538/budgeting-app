# frozen_string_literal: true

class Api::V1::DashboardController < ApplicationController
  def index
    render json: DashboardService.new(current_user).summary
  end
end
