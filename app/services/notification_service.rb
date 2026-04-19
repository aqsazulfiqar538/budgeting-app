# frozen_string_literal: true

class NotificationService
  class << self
    def expense_created(expense, actor)
      recipients = expense.participants.where.not(id: actor.id)
      notify_all(
        recipients: recipients,
        actor: actor,
        type: :expense_added,
        content: "#{actor.full_name} added '#{expense.title}' — Rs. #{expense.amount}",
        source: expense
      )
    end

    def expense_updated(expense, actor)
      recipients = expense.participants.where.not(id: actor.id)
      notify_all(
        recipients: recipients,
        actor: actor,
        type: :expense_updated,
        content: "#{actor.full_name} updated '#{expense.title}'",
        source: expense
      )
    end

    def expense_deleted(expense, actor)
      recipients = expense.participants.where.not(id: actor.id)
      notify_all(
        recipients: recipients,
        actor: actor,
        type: :expense_deleted,
        content: "#{actor.full_name} deleted '#{expense.title}'",
        source: expense
      )
    end

    def comment_added(comment)
      recipients = comment.expense.participants.where.not(id: comment.user_id)
      notify_all(
        recipients: recipients,
        actor: comment.user,
        type: :comment_added,
        content: "#{comment.user.full_name} commented on '#{comment.expense.title}'",
        source: comment.expense
      )
    end

    def added_to_group(group, user, actor)
      notify(
        recipient: user,
        actor: actor,
        type: :added_to_group,
        content: "#{actor.full_name} added you to '#{group.name}'",
        source: group
      )
    end

    def removed_from_group(group, user, actor)
      notify(
        recipient: user,
        actor: actor,
        type: :removed_from_group,
        content: "#{actor.full_name} removed you from '#{group.name}'",
        source: group
      )
    end

    def friend_request_sent(friendship, requester, recipient)
      notify(
        recipient: recipient,
        actor: requester,
        type: :friend_added,
        content: "#{requester.full_name} sent you a friend request",
        source: friendship
      )
    end

    def friend_request_accepted(friendship, acceptor, requester)
      notify(
        recipient: requester,
        actor: acceptor,
        type: :friend_added,
        content: "#{acceptor.full_name} accepted your friend request",
        source: friendship
      )
    end

    def debt_settled(repayment, actor)
      other = repayment.from_user_id == actor.id ? repayment.to_user : repayment.from_user
      notify(
        recipient: other,
        actor: actor,
        type: :debt_settled,
        content: "#{actor.full_name} settled Rs. #{repayment.amount} for '#{repayment.expense.title}'",
        source: repayment.expense
      )
    end

    private

    def notify(recipient:, actor:, type:, content:, source: nil)
      Notification.create!(
        user: recipient,
        created_by: actor,
        notification_type: type,
        content: content,
        source: source
      )
    end

    def notify_all(recipients:, actor:, type:, content:, source: nil)
      recipients.find_each do |recipient|
        notify(recipient: recipient, actor: actor, type: type, content: content, source: source)
      end
    end
  end
end
