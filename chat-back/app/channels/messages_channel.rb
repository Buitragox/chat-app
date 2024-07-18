# frozen_string_literal: true

class MessagesChannel < ApplicationCable::Channel
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def subscribed
    receiver = User.find_by!(email: params[:receiver_email])

    @conversation_id = UsersConversation.find_conversation_id(current_user, receiver)

    if @conversation_id.nil?
      @conversation_id = Conversation.create.id
      UsersConversation.create([{ user_id: current_user.id, conversation_id: @conversation_id },
                                { user_id: receiver.id, conversation_id: @conversation_id }])
    end

    stream_from "conversation_#{@conversation_id}"
  rescue StandardError => e
    # rescue_from does not work correctly with the `subscribed` method: https://github.com/rails/rails/issues/51855
    rescue_with_handler(e)
  end

  def receive(data)
    raise ActiveRecord::RecordNotFound if data['body'].include?('error')

    body = data['body']
    message = Message.create(conversation_id: @conversation_id, user_id: current_user.id, body:)
    ActionCable.server.broadcast("conversation_#{@conversation_id}", message)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # We can create methods that the frontend can call by using the `perform` method.
  # For example: This method returns the conversation id.
  def conversation_id
    transmit({ conversation_id: @conversation_id })
  end

  private

  def record_not_found(e)
    Rails.logger.info 'User not found.'
    transmit({ error: "User '#{params[:receiver_id]}' not found." })
    reject
  end

end
