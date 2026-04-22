require 'rails_helper'

RSpec.describe Category, type: :model do

  describe "validations" do
    context "when name is present" do
      before { @category = build(:category, name: "Food") }

      it "is valid" do
        expect(@category).to be_valid
      end
    end

    context "when name is absent" do
      before { @category = build(:category, name: nil) }

      it "is invalid" do
        expect(@category).not_to be_valid
      end

      it "has an error on name" do
        @category.valid?
        expect(@category.errors[:name]).to include("can't be blank")
      end
    end
  end

  describe "active column" do
    context "when a category is created without specifying active" do
      before { @category = create(:category) }

      it "defaults to true" do
        expect(@category.active).to be(true)
      end
    end

    context "when a category is explicitly set to inactive" do
      before { @category = create(:category, active: false) }

      it "is not active" do
        expect(@category.active).to be(false)
      end
    end
  end

  describe "associations" do
    context "when a category belongs to a user" do
      before do
        @user     = create(:user)
        @category = create(:category, :custom, user: @user)
      end

      it "is associated with the user" do
        expect(@category.user).to eq(@user)
      end
    end

    context "when a category has no user" do
      before { @category = create(:category) }

      it "is valid without a user" do
        expect(@category.user).to be_nil
        expect(@category).to be_valid
      end
    end

    context "when a category has a parent" do
      before do
        @parent   = create(:category)
        @child    = create(:category, parent: @parent)
      end

      it "is associated with the parent" do
        expect(@child.parent).to eq(@parent)
      end
    end

    context "when a category has no parent" do
      before { @category = create(:category) }

      it "is valid without a parent" do
        expect(@category.parent).to be_nil
        expect(@category).to be_valid
      end
    end

    context "when a parent category has subcategories" do
      before do
        @parent = create(:category)
        @child1 = create(:category, parent: @parent)
        @child2 = create(:category, parent: @parent)
      end

      it "includes all subcategories" do
        expect(@parent.subcategories).to include(@child1, @child2)
      end
    end

    context "when a parent category is destroyed" do
      before do
        @parent = create(:category)
        @child  = create(:category, parent: @parent)
      end

      it "destroys all subcategories" do
        expect { @parent.destroy }.to change { Category.count }.by(-2)
      end
    end

    context "when a category has no subcategories and is destroyed" do
      before { @category = create(:category) }

      it "destroys only itself" do
        expect { @category.destroy }.to change { Category.count }.by(-1)
      end
    end

    context "when a category has expenses attached" do
      before do
        @user     = create(:user)
        @category = create(:category)
        @expense  = create(:expense, user: @user, category: @category)
      end

      it "cannot be destroyed" do
        expect { @category.destroy }.not_to change { Category.count }
      end

      it "has an error after failed destroy" do
        @category.destroy
        expect(@category.errors).not_to be_empty
      end
    end
  end

  describe "scopes" do
    context "when system and custom categories both exist" do
      before do
        @system_category = create(:category)
        @custom_category = create(:category, :custom)
      end

      it "system_categories includes only categories with no user" do
        expect(Category.system_categories).to include(@system_category)
      end

      it "system_categories excludes user-owned categories" do
        expect(Category.system_categories).not_to include(@custom_category)
      end
    end
  end

  describe "#parent_must_be_system_or_own" do
    context "when parent is a system category" do
      before do
        @user          = create(:user)
        @system_parent = create(:category)
        @category      = build(:category, :custom, user: @user, parent: @system_parent)
      end

      it "is valid" do
        expect(@category).to be_valid
      end
    end

    context "when parent belongs to the same user" do
      before do
        @user       = create(:user)
        @own_parent = create(:category, :custom, user: @user)
        @category   = build(:category, :custom, user: @user, parent: @own_parent)
      end

      it "is valid" do
        expect(@category).to be_valid
      end
    end

    context "when parent belongs to a different user" do
      before do
        @user         = create(:user)
        @other_user   = create(:user)
        @other_parent = create(:category, :custom, user: @other_user)
        @category     = build(:category, :custom, user: @user, parent: @other_parent)
      end

      it "is invalid" do
        expect(@category).not_to be_valid
      end

      it "has an error on parent_id" do
        @category.valid?
        expect(@category.errors[:parent_id]).to include("must be a system category or your own category")
      end
    end

    context "when category has no parent" do
       before { @category = build(:category, :custom) }

      it "is valid without triggering parent validation" do
        expect(@category).to be_valid
      end
    end
  end
end
