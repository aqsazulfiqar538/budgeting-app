# spec/models/notification_spec.rb
require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    context "when all required fields are present" do
      it "is valid" do
        expect(build(:notification)).to be_valid
      end
    end

    context "when content is missing" do
      before { @notification = build(:notification, content: nil) }

      it "is invalid" do
        expect(@notification).not_to be_valid
      end

      it "has an error on content" do
        @notification.valid?
        expect(@notification.errors[:content]).to include("can't be blank")
      end
    end
  end

  describe "associations" do
    before do
      @user = create(:user)
      @creator = create(:user)
      @notification = create(:notification, user: @user, created_by: @creator)
    end

    it "belongs to a user" do
      expect(@notification.user).to eq(@user)
    end

    it "belongs to a creator" do
      expect(@notification.created_by).to eq(@creator)
    end

    context "polymorphic source" do
      before do
        @group = create(:group)
        @notification = create(:notification, source: @group)
      end

      it "can belong to a polymorphic source" do
        expect(@notification.source).to eq(@group)
      end

      it "stores the correct source type" do
        expect(@notification.source_type).to eq("Group")
      end

      it "stores the correct source id" do
        expect(@notification.source_id).to eq(@group.id)
      end
    end

    context "when source is absent" do
      before { @notification = create(:notification, source: nil) }

      it "is still valid without a source" do
        expect(@notification).to be_valid
      end
    end
  end

  describe "enums" do
    let(:types) do
      %i[expense_added expense_updated expense_deleted comment_added
         added_to_group removed_from_group group_deleted
         friend_added friend_removed debt_settled]
    end

    it "supports all notification types" do
      types.each do |type|
        notification = build(:notification, notification_type: type)
        expect(notification.send(:"#{type}?")).to be(true)
      end
    end
  end

  describe "scopes" do
    context "unread scope" do
      before do
        @unread = create(:notification, read_at: nil)
        @read   = create(:notification, read_at: Time.current)
      end

      it "includes unread notifications" do
        expect(Notification.unread).to include(@unread)
      end

      it "excludes read notifications" do
        expect(Notification.unread).not_to include(@read)
      end
    end

    context "recent scope" do
      before do
        @older = create(:notification, created_at: 2.days.ago)
        @newer = create(:notification, created_at: 1.day.ago)
      end

      it "orders notifications by created_at descending" do
        expect(Notification.recent.first).to eq(@newer)
        expect(Notification.recent.last).to eq(@older)
      end
    end
  end
end
