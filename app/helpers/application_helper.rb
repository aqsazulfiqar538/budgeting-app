module ApplicationHelper
  def format_rupees(amount)
    number_to_currency(amount || 0, unit: "Rs. ", delimiter: ",", separator: ".")
  end
end
