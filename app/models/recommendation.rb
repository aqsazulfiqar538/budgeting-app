class Recommendation < ApplicationRecord
  CATEGORIES = %w[food travel medication].freeze

  include Categorizable

  belongs_to :user

  enum :action, {
    none:                 0,
    review_spending:      1,
    set_budget_limit:     2,
    seek_alternatives:    3,
    urgent_intervention:  4
  }

  ACTION_LABELS = {
    "none"                => "Looks good",
    "review_spending"     => "Review your spending",
    "set_budget_limit"    => "Set a budget limit",
    "seek_alternatives"   => "Find cheaper alternatives"
  }.freeze

  def action_label
    ACTION_LABELS[action] || "No action"
  end
end
