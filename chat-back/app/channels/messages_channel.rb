# frozen_string_literal: true
class MessagesChannel < ApplicationCable::Channel
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def subscribed
    # TODO: handle error when no params are present
    receiver = User.find_by!(email: params[:receiver_email])

    @conversation_id = UsersConversation.select('conversation_id').where(user_id: [current_user.id, receiver.id])
                                        .group('conversation_id').having('COUNT(DISTINCT user_id) = 2')
                                        .pick(:conversation_id)

    if @conversation_id.nil?
      @conversation_id = Conversation.create.id
      UsersConversation.create([{ user_id: current_user.id, conversation_id: @conversation_id },
                                { user_id: receiver.id, conversation_id: @conversation_id }])
    end

    stream_from "conversation_#{@conversation_id}"
  end

  def receive(data)
    body = data['body']
    message = Message.create(conversation_id: @conversation_id, user_id: current_user.id, body:)
    ActionCable.server.broadcast("conversation_#{@conversation_id}", message)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def record_not_found
    Rails.logger.info 'User not found. Rejecting...'
    transmit({ error: "User '#{params[:receiver_id]}' not found." })
    reject
  end

  # We can create methods that the frontend can call by using the `perform` method.

  # For example: This method returns the conversation id.
  def connection_id
    transmit({ conversation_id: @conversation_id })
  end

end
