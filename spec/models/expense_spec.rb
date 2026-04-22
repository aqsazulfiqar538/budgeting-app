require 'rails_helper'

RSpec.describe Expense, type: :model do

  describe "validations" do
    context "when all required fields are present" do
      before { @expense = build(:expense) }

      it "is valid" do
        expect(@expense).to be_valid
      end
    end

    context "when title is absent" do
      before { @expense = build(:expense, title: nil) }

      it "is invalid" do
        expect(@expense).not_to be_valid
      end

      it "has an error on title" do
        @expense.valid?
        expect(@expense.errors[:title]).to include("can't be blank")
      end
    end

    context "when amount is absent" do
      before { @expense = build(:expense, amount: nil) }

      it "is invalid" do
        expect(@expense).not_to be_valid
      end

      it "has an error on amount" do
        @expense.valid?
        expect(@expense.errors[:amount]).to include("can't be blank")
      end
    end

    context "when amount is zero" do
      before { @expense = build(:expense, amount: 0) }

      it "is invalid" do
        expect(@expense).not_to be_valid
      end

      it "has an error on amount" do
        @expense.valid?
        expect(@expense.errors[:amount]).to include("must be greater than 0")
      end
    end

    context "when amount is negative" do
      before { @expense = build(:expense, amount: -10) }

      it "is invalid" do
        expect(@expense).not_to be_valid
      end

      it "has an error on amount" do
        @expense.valid?
        expect(@expense.errors[:amount]).to include("must be greater than 0")
      end
    end

    context "when amount is positive" do
      before { @expense = build(:expense, amount: 99.99) }

      it "is valid" do
        expect(@expense).to be_valid
      end
    end

    context "when start_date is absent" do
      before { @expense = build(:expense, start_date: nil) }

      it "is invalid" do
        expect(@expense).not_to be_valid
      end

      it "has an error on start_date" do
        @expense.valid?
        expect(@expense.errors[:start_date]).to include("can't be blank")
      end
    end
  end

  describe "associations" do
    context "when expense belongs to a user" do
      before do
        @user    = create(:user)
        @expense = create(:expense, user: @user)
      end

      it "is associated with the correct user" do
        expect(@expense.user).to eq(@user)
      end
    end

    context "when expense belongs to a category" do
      before do
        @category = create(:category)
        @expense  = create(:expense, category: @category)
      end

      it "is associated with the correct category" do
        expect(@expense.category).to eq(@category)
      end
    end

    context "when expense belongs to a group" do
      before do
        @group   = create(:group)
        @expense = create(:expense, group: @group)
      end

      it "is associated with the correct group" do
        expect(@expense.group).to eq(@group)
      end
    end

    context "when expense has no group" do
      before { @expense = create(:expense, group: nil) }

      it "is valid without a group" do
        expect(@expense.group).to be_nil
        expect(@expense).to be_valid
      end
    end

    context "when expense has participants" do
      before do
        @expense      = create(:expense)
        @participant1 = create(:expense_participant, expense: @expense)
        @participant2 = create(:expense_participant, expense: @expense)
      end

      it "includes all participants" do
        expect(@expense.expense_participants).to include(@participant1, @participant2)
      end
    end

    context "when expense is destroyed" do
      before do
        @expense     = create(:expense)
        @participant = create(:expense_participant, expense: @expense)
        @repayment   = create(:repayment, expense: @expense)
        @comment     = create(:comment, expense: @expense)
      end

      it "destroys associated expense_participants" do
        expect { @expense.destroy }.to change { ExpenseParticipant.count }.by(-1)
      end

      it "destroys associated repayments" do
        expect { @expense.destroy }.to change { Repayment.count }.by(-1)
      end

      it "destroys associated comments" do
        expect { @expense.destroy }.to change { Comment.count }.by(-1)
      end
    end

    context "when expense has repayments" do
      before do
        @expense   = create(:expense)
        @repayment = create(:repayment, expense: @expense)
      end

      it "includes the repayment" do
        expect(@expense.repayments).to include(@repayment)
      end
    end

    context "when expense has comments" do
      before do
        @expense = create(:expense)
        @comment = create(:comment, expense: @expense)
      end

      it "includes the comment" do
        expect(@expense.comments).to include(@comment)
      end
    end
  end

  describe "scopes" do
    context "when some expenses are soft deleted" do
      before do
        @active_expense  = create(:expense)
        @deleted_expense = create(:expense, deleted_at: Time.current)
      end

      it "active scope includes non-deleted expenses" do
        expect(Expense.active).to include(@active_expense)
      end

      it "active scope excludes deleted expenses" do
        expect(Expense.active).not_to include(@deleted_expense)
      end
    end

    context "when expenses have different start dates" do
      before do
        @older_expense = create(:expense, start_date: 2.weeks.ago)
        @newer_expense = create(:expense, start_date: Date.current)
      end

      it "recent scope returns newer expenses first" do
        expect(Expense.recent.first).to eq(@newer_expense)
      end

      it "recent scope returns older expenses last" do
        expect(Expense.recent.last).to eq(@older_expense)
      end
    end

    context "when user is the payer of an active expense" do
      before do
        @user    = create(:user)
        @expense = create(:expense, user: @user)
      end

      it "visible_to includes the expense" do
        expect(Expense.visible_to(@user)).to include(@expense)
      end
    end

    context "when user is a participant of an active expense" do
      before do
        @user    = create(:user)
        @expense = create(:expense)
        create(:expense_participant, expense: @expense, user: @user)
      end

      it "visible_to includes the expense" do
        expect(Expense.visible_to(@user)).to include(@expense)
      end
    end

    context "when user is neither payer nor participant" do
      before do
        @user    = create(:user)
        @expense = create(:expense)
      end

      it "visible_to excludes the expense" do
        expect(Expense.visible_to(@user)).not_to include(@expense)
      end
    end

    context "when expense is deleted and user is the payer" do
      before do
        @user    = create(:user)
        @expense = create(:expense, user: @user, deleted_at: Time.current)
      end

      it "visible_to excludes the deleted expense" do
        expect(Expense.visible_to(@user)).not_to include(@expense)
      end
    end
  end

  describe "#shared?" do
    context "when expense has more than one participant" do
      before do
        @expense = create(:expense)
        create(:expense_participant, expense: @expense)
        create(:expense_participant, expense: @expense)
      end

      it "returns true" do
        expect(@expense.shared?).to be(true)
      end
    end

    context "when expense has one or no participants" do
      before do
        @expense = create(:expense)
        create(:expense_participant, expense: @expense)
      end

      it "returns false" do
        expect(@expense.shared?).to be(false)
      end
    end

    context "when expense has no participants" do
      before { @expense = create(:expense) }

      it "returns false" do
        expect(@expense.shared?).to be(false)
      end
    end
  end

  describe "#category_accessible_to_user" do
    context "when category is a system category" do
      before do
        @user     = create(:user)
        @category = create(:category)
        @expense  = build(:expense, user: @user, category: @category)
      end

      it "is valid" do
        expect(@expense).to be_valid
      end
    end

    context "when category belongs to the same user" do
      before do
        @user     = create(:user)
        @category = create(:category, :custom, user: @user)
        @expense  = build(:expense, user: @user, category: @category)
      end

      it "is valid" do
        expect(@expense).to be_valid
      end
    end

    context "when category belongs to a different user" do
      before do
        @user       = create(:user)
        @other_user = create(:user)
        @category   = create(:category, :custom, user: @other_user)
        @expense    = build(:expense, user: @user, category: @category)
      end

      it "is invalid" do
        expect(@expense).not_to be_valid
      end

      it "has an error on category" do
        @expense.valid?
        expect(@expense.errors[:category]).to include("is not accessible")
      end
    end
  end

  describe "optional fields" do
    context "when end_date is absent" do
      before { @expense = build(:expense, end_date: nil) }

      it "is valid without end_date" do
        expect(@expense).to be_valid
      end
    end

    context "when notes are absent" do
      before { @expense = build(:expense, notes: nil) }

      it "is valid without notes" do
        expect(@expense).to be_valid
      end
    end

    context "when deleted_at is absent" do
      before { @expense = build(:expense, deleted_at: nil) }

      it "is valid without deleted_at" do
        expect(@expense).to be_valid
      end
    end
  end

end
