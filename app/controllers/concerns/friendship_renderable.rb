# frozen_string_literal: true

module FriendshipRenderable
  extend ActiveSupport::Concern

  private

  def render_paginated_friendships(collection)
    pagy, records = pagy(collection)
    render json: {
      **FriendshipSerializer.new(records, params: { current_user: current_user }).serializable_hash,
      meta: pagy_metadata(pagy)
    }
  end
end
