require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe "validations" do
    context "when all required fields are present" do
      before { @comment = build(:comment) }

      it "is valid" do
        expect(@comment).to be_valid
      end
    end

    context "when content is absent" do
      before { @comment = build(:comment, content: nil) }

      it "is invalid" do
        expect(@comment).not_to be_valid
      end

      it "has an error on content" do
        @comment.valid?
        expect(@comment.errors[:content]).to include("can't be blank")
      end
    end
  end

  describe "associations" do
    context "when comment belongs to an expense" do
      before do
        @expense = create(:expense)
        @comment = create(:comment, expense: @expense)
      end

      it "is associated with the correct expense" do
        expect(@comment.expense).to eq(@expense)
      end
    end

    context "when comment belongs to a user" do
      before do
        @user    = create(:user)
        @comment = create(:comment, user: @user)
      end

      it "is associated with the correct user" do
        expect(@comment.user).to eq(@user)
      end
    end
  end

  describe "enums" do
    context "when comment type is user_comment" do
      before { @comment = create(:comment, comment_type: :user_comment) }

      it "is a user comment" do
        expect(@comment.user_comment?).to be(true)
      end
    end

    context "when comment type is system_comment" do
      before { @comment = create(:comment, comment_type: :system_comment) }

      it "is a system comment" do
        expect(@comment.system_comment?).to be(true)
      end
    end

    context "default comment type" do
      before { @comment = create(:comment) }

      it "defaults to user_comment" do
        expect(@comment.user_comment?).to be(true)
      end
    end
  end
end
