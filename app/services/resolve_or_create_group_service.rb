# frozen_string_literal: true

class ResolveOrCreateGroupService
  def initialize(user:, group_id: nil, group_params: nil, participant_ids: [])
    @user            = user
    @group_id        = group_id
    @group_params    = group_params
    @participant_ids = participant_ids
  end

  def call
    return group_id if group_id.present?
    return nil unless group_params.present?

    create_group_with_members.id
  end

  private

  attr_reader :user, :group_id, :group_params, :participant_ids

  def create_group_with_members
    begin
        group = user.created_groups.create!(
        name:       group_params[:name],
        group_type: group_params[:group_type] || :other
        )
        group.group_memberships.create!(user_id: user.id)
        add_participants(group)
        group
    rescue ActiveRecord::RecordInvalid => e
        render_error(e.full_messages)
    end
  end

  def add_participants(group)
    friend_ids = user.friends.pluck(:id)

    participant_ids.each do |uid|
      next if uid == user.id
      group.group_memberships.create!(user_id: uid)
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.full_messages)
      end
    end
  end
end
