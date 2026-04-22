require 'rails_helper'

RSpec.describe ExpenseParticipant, type: :model do
  describe "validations" do
    context "when all required fields are present" do
      before { @participant = build(:expense_participant) }

      it "is valid" do
        expect(@participant).to be_valid
      end
    end

    context "when paid_share is negative" do
      before { @participant = build(:expense_participant, paid_share: -10) }

      it "is invalid" do
        expect(@participant).not_to be_valid
      end

      it "has an error on paid_share" do
        @participant.valid?
        expect(@participant.errors[:paid_share]).to include("must be greater than or equal to 0")
      end
    end

    context "when owed_share is negative" do
      before { @participant = build(:expense_participant, owed_share: -5) }

      it "is invalid" do
        expect(@participant).not_to be_valid
      end

      it "has an error on owed_share" do
        @participant.valid?
        expect(@participant.errors[:owed_share]).to include("must be greater than or equal to 0")
      end
    end

    context "when same user is added twice to same expense" do
      before do
        @expense = create(:expense)
        @user    = create(:user)
        create(:expense_participant, expense: @expense, user: @user)

        @duplicate = build(:expense_participant, expense: @expense, user: @user)
      end

      it "is invalid" do
        expect(@duplicate).not_to be_valid
      end

      it "has an error on user_id" do
        @duplicate.valid?
        expect(@duplicate.errors[:user_id]).to include("is already a participant")
      end
    end
  end

  describe "associations" do
    context "when participant belongs to an expense" do
      before do
        @expense     = create(:expense)
        @participant = create(:expense_participant, expense: @expense)
      end

      it "is associated with the correct expense" do
        expect(@participant.expense).to eq(@expense)
      end
    end

    context "when participant belongs to a user" do
      before do
        @user        = create(:user)
        @participant = create(:expense_participant, user: @user)
      end

      it "is associated with the correct user" do
        expect(@participant.user).to eq(@user)
      end
    end
  end

  describe "#net_balance" do
    context "when owed_share is greater than paid_share" do
      before { @participant = build(:expense_participant, owed_share: 100, paid_share: 40) }

      it "returns positive balance" do
        expect(@participant.net_balance).to eq(60)
      end
    end

    context "when paid_share is greater than owed_share" do
      before { @participant = build(:expense_participant, owed_share: 30, paid_share: 80) }

      it "returns negative balance" do
        expect(@participant.net_balance).to eq(-50)
      end
    end

    context "when paid_share equals owed_share" do
      before { @participant = build(:expense_participant, owed_share: 50, paid_share: 50) }

      it "returns zero" do
        expect(@participant.net_balance).to eq(0)
      end
    end
  end
end
