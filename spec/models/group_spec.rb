# spec/models/group_spec.rb
require "rails_helper"

RSpec.describe Group, type: :model do
  describe "validations" do
    context "when all required fields are present" do
      before do
        @group = build(:group)
      end

      it "is valid" do
        expect(@group).to be_valid
      end
    end

    context "when name is missing" do
      before do
        @group = build(:group, name: nil)
      end

      it "is invalid" do
        expect(@group).not_to be_valid
      end

      it "has an error on name" do
        @group.valid?
        expect(@group.errors[:name]).to include("can't be blank")
      end
    end
  end

  describe "associations" do
    context "creator" do
      before do
        @creator = create(:user)
        @group = create(:group, creator: @creator)
      end

      it "belongs to a creator" do
        expect(@group.creator).to eq(@creator)
      end
    end

    context "group_memberships" do
      before do
        @group = create(:group)
        @membership = create(:group_membership, group: @group)
      end

      it "has many group_memberships" do
        expect(@group.group_memberships).to include(@membership)
      end

      it "destroys memberships when group is destroyed" do
        membership_id = @membership.id
        @group.destroy
        expect(GroupMembership.exists?(membership_id)).to be(false)
      end
    end

    context "users through group_memberships" do
      before do
        @group = create(:group)
        @user = create(:user)
        create(:group_membership, group: @group, user: @user)
      end

      it "has many users through group_memberships" do
        expect(@group.users).to include(@user)
      end
    end

    context "expenses" do
      before do
        @group = create(:group)
        @expense = create(:expense, group: @group)
      end

      it "has many expenses" do
        expect(@group.expenses).to include(@expense)
      end

      it "nullifies expenses when group is destroyed" do
        @group.destroy
        expect(@expense.reload.group_id).to be_nil
      end
    end
  end

  describe "enums" do
    context "group_type" do
      it "defaults to other" do
        group = create(:group)
        expect(group.other?).to be(true)
      end

      it "can be home" do
        expect(create(:group, group_type: :home).home?).to be(true)
      end

      it "can be trip" do
        expect(create(:group, group_type: :trip).trip?).to be(true)
      end

      it "can be couple" do
        expect(create(:group, group_type: :couple).couple?).to be(true)
      end

      it "can be apartment" do
        expect(create(:group, group_type: :apartment).apartment?).to be(true)
      end
    end
  end

  describe "#member?" do
    before do
      @group = create(:group)
      @member = create(:user)
      @non_member = create(:user)
      create(:group_membership, group: @group, user: @member)
    end

    it "returns true for a member" do
      expect(@group.member?(@member)).to be(true)
    end

    it "returns false for a non-member" do
      expect(@group.member?(@non_member)).to be(false)
    end
  end
end
