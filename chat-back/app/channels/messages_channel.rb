# frozen_string_literal: true
class MessagesChannel < ApplicationCable::Channel

  def subscribed
    # TODO: Raise and error when no params are present
    Rails.logger.info "Params: #{params}"
    # raise StandardError, ""
    receiver = User.find_by!(email: params[:receiver_email])
    Rails.logger.info "Current user: #{current_user.inspect}"

    @conversation_id = UsersConversation.select('conversation_id').where(user_id: [current_user.id, receiver.id])
                                        .group('conversation_id').having('COUNT(DISTINCT user_id) = 2')
                                        .pick(:conversation_id)

    if @conversation_id.nil?
      @conversation_id = Conversation.create.id
      UsersConversation.create([{ user_id: current_user.id, conversation_id: @conversation_id },
                                { user_id: receiver.id, conversation_id: @conversation_id }])
    end

    stream_from "conversation_#{@conversation_id}"

  rescue ActiveRecord::RecordNotFound
    Rails.logger.info 'User not found. Rejecting...'
    # connection.transmit(error: "User #{params[:receiver_id]} not found.")
    transmit({ error: "User '#{params[:receiver_id]}' not found." })
    reject
  rescue StandardError => e
    Rails.logger.error e
    reject
  end

  def receive(data)
    Rails.logger.info "Received message #{data}, conversation_id: #{@conversation_id}"
    body = data['body']
    message = Message.create(conversation_id: @conversation_id, user_id: current_user.id, body:)
    Rails.logger.info "Message created: #{message.inspect}"
    ActionCable.server.broadcast("conversation_#{@conversation_id}", message)
    ActionCable.server.broadcast('MessagesChannel', message)
  end

  def connection_id
    transmit({ conversation_id: @conversation_id })
  end


  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end
