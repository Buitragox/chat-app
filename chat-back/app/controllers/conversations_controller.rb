class ConversationsController < ApplicationController
  before_action :set_conversation, only: %i[show]

  def show
    messages = @conversation.messages.all
    # Rails.logger.info "Show messages: #{messages.inspect}"
    render json: messages
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
