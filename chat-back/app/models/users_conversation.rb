# frozen_string_literal: true

# nodoc
class UsersConversation < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  def inspect
    "<UserConversation user_id: #{user_id}, conversation_id: #{conversation_id}>"
  end
end
