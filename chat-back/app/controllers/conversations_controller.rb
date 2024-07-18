class ConversationsController < ApplicationController
  before_action :set_conversation, only: %i[show]

  # NOTE: Should add pagination
  def show
    messages = @conversation.messages.all
    render json: messages
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
