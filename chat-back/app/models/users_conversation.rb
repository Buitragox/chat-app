# frozen_string_literal: true

# nodoc
class UsersConversation < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  # Find the conversation_id for the conversation between the current_user and the receiver.
  def self.find_conversation_id(current_user, receiver)
    UsersConversation.select('conversation_id').where(user_id: [current_user.id, receiver.id])
                     .group('conversation_id').having('COUNT(DISTINCT user_id) = 2')
                     .pick(:conversation_id)
  end

  def inspect
    "<UserConversation user_id: #{user_id}, conversation_id: #{conversation_id}>"
  end
end
