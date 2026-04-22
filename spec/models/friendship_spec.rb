require 'rails_helper'

RSpec.describe Friendship, type: :model do
  describe "validations" do
    context "when all required fields are valid" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)
        @friendship = build(:friendship, user: @user1, friend: @user2, requester: @user1)
      end

      it "is valid" do
        expect(@friendship).to be_valid
      end
    end

    context "when friendship already exists between same users" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)

        create(:friendship, user: @user1, friend: @user2, requester: @user1)

        @duplicate = build(:friendship, user: @user1, friend: @user2, requester: @user1)
      end

      it "is invalid" do
        expect(@duplicate).not_to be_valid
      end

      it "has an error on user_id" do
        @duplicate.valid?
        expect(@duplicate.errors[:user_id]).to include("friendship already exists")
      end
    end

    context "when trying to friend oneself" do
      before do
        @user = create(:user)
        @friendship = build(:friendship, user: @user, friend: @user, requester: @user)
      end

      it "is invalid" do
        expect(@friendship).not_to be_valid
      end

      it "has an error on base" do
        @friendship.valid?
        expect(@friendship.errors[:base]).to include("Cannot befriend yourself")
      end
    end

    context "when canonical ordering is violated" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)

        # force invalid ordering manually
        @friendship = build(:friendship, user: @user2, friend: @user1, requester: @user1)
      end

      it "is invalid" do
        expect(@friendship).not_to be_valid
      end

      it "has an error on base" do
        @friendship.valid?
        expect(@friendship.errors[:base]).to include("Invalid friendship: IDs must be canonically ordered")
      end
    end
  end

  describe "associations" do
    context "when friendship belongs to user, friend and requester" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)
        @user3 = create(:user)

        @friendship = create(
          :friendship,
          user: @user1,
          friend: @user2,
          requester: @user3
        )
      end

      it "has correct user" do
        expect(@friendship.user).to eq(@user1)
      end

      it "has correct friend" do
        expect(@friendship.friend).to eq(@user2)
      end

      it "has correct requester" do
        expect(@friendship.requester).to eq(@user3)
      end
    end
  end

  describe "enums" do
    context "when status is pending" do
      before { @friendship = create(:friendship, status: :pending) }

      it "is pending" do
        expect(@friendship.pending?).to be(true)
      end
    end

    context "when status is accepted" do
      before { @friendship = create(:friendship, status: :accepted) }

      it "is accepted" do
        expect(@friendship.accepted?).to be(true)
      end
    end

    context "when status is rejected" do
      before { @friendship = create(:friendship, status: :rejected) }

      it "is rejected" do
        expect(@friendship.rejected?).to be(true)
      end
    end
  end

  describe "scopes" do
    context "involving scope" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)
        @user3 = create(:user)

        @friendship = create(:friendship, user: @user1, friend: @user2, requester: @user1)
      end

      it "includes friendships where user is user_id" do
        expect(Friendship.involving(@user1)).to include(@friendship)
      end

      it "includes friendships where user is friend_id" do
        expect(Friendship.involving(@user2)).to include(@friendship)
      end

      it "excludes unrelated user" do
        expect(Friendship.involving(@user3)).not_to include(@friendship)
      end
    end

    context "accepted scope" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)
				@user3 = create(:user)

        @accepted_friendship = create(:friendship, user: @user1, friend: @user2, requester: @user1, status: :accepted)
        @pending_friendship  = create(:friendship, user: @user1, friend: @user3, requester: @user1, status: :pending)
      end

      it "includes accepted friendships" do
        expect(Friendship.accepted).to include(@accepted_friendship)
      end

      it "excludes non-accepted friendships" do
        expect(Friendship.accepted).not_to include(@pending_friendship)
      end
    end

    context "pending_for scope" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)

        @friendship = create(:friendship, user: @user1, friend: @user2, requester: @user1, status: :pending)
      end

      it "includes pending requests for recipient" do
        expect(Friendship.pending_for(@user2)).to include(@friendship)
      end

      it "excludes requester from pending_for" do
        expect(Friendship.pending_for(@user1)).not_to include(@friendship)
      end
    end
  end

  describe "#other_user" do
    context "when current user is user" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)

        @friendship = create(:friendship, user: @user1, friend: @user2, requester: @user1)
      end

      it "returns friend" do
        expect(@friendship.other_user(@user1)).to eq(@user2)
      end
    end

    context "when current user is friend" do
      before do
        @user1 = create(:user)
        @user2 = create(:user)

        @friendship = create(:friendship, user: @user1, friend: @user2, requester: @user1)
      end

      it "returns user" do
        expect(@friendship.other_user(@user2)).to eq(@user1)
      end
    end
  end
end
