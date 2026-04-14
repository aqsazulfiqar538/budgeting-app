# == Schema Information
#
# Table name: messages
#
#  id                    :integer          not null, primary key
#  role                  :string           not null
#  content               :text
#  content_raw           :json
#  thinking_text         :text
#  thinking_signature    :text
#  thinking_tokens       :integer
#  input_tokens          :integer
#  output_tokens         :integer
#  cached_tokens         :integer
#  cache_creation_tokens :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  chat_id               :integer          not null
#  model_id              :integer
#  tool_call_id          :integer
#
# Indexes
#
#  index_messages_on_chat_id       (chat_id)
#  index_messages_on_model_id      (model_id)
#  index_messages_on_role          (role)
#  index_messages_on_tool_call_id  (tool_call_id)
#

class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments
end
