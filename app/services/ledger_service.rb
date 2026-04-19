# frozen_string_literal: true

class LedgerService
  def initialize(user)
    @user = user
  end

  def summary
    owed_to_me_data = Repayment.where(settled: false, to_user_id: @user.id)
                               .group(:from_user_id)
                               .sum(:amount)

    i_owe_data = Repayment.where(settled: false, from_user_id: @user.id)
                           .group(:to_user_id)
                           .sum(:amount)

    all_user_ids = (owed_to_me_data.keys + i_owe_data.keys).uniq
    users = User.where(id: all_user_ids).index_by(&:id)

    owed_list = owed_to_me_data.filter_map do |uid, amount|
      u = users[uid]
      next unless u
      u.summary.merge(amount: amount)
    end

    owe_list = i_owe_data.filter_map do |uid, amount|
      u = users[uid]
      next unless u
      u.summary.merge(amount: amount)
    end

    {
      i_owe: owe_list,
      owed_to_me: owed_list,
      total_i_owe: owe_list.sum { |e| e[:amount] },
      total_owed_to_me: owed_list.sum { |e| e[:amount] }
    }
  end

  def detail(friend_id)
    friend = User.find(friend_id)
    unless @user.friends.exists?(id: friend.id)
      return { error: "Not friends with this user" }
    end

    they_owe_me = Repayment.where(settled: false, from_user_id: friend.id, to_user_id: @user.id)
                           .includes(:expense)

    i_owe_them = Repayment.where(settled: false, from_user_id: @user.id, to_user_id: friend.id)
                          .includes(:expense)

    {
      friend: friend.summary,
      they_owe_me: they_owe_me.map { |r| repayment_detail(r) },
      i_owe_them: i_owe_them.map { |r| repayment_detail(r) },
      total_they_owe_me: they_owe_me.sum(:amount),
      total_i_owe_them: i_owe_them.sum(:amount),
      net: they_owe_me.sum(:amount) - i_owe_them.sum(:amount)
    }
  end

  private

  def repayment_detail(repayment)
    {
      id: repayment.id,
      amount: repayment.amount,
      expense_title: repayment.expense&.title,
      expense_id: repayment.expense_id,
      created_at: repayment.created_at
    }
  end
end
