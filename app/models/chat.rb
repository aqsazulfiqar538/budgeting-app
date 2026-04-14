# == Schema Information
#
# Table name: chats
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  model_id   :integer
#
# Indexes
#
#  index_chats_on_model_id  (model_id)
#

class Chat < ApplicationRecord
  acts_as_chat
end
