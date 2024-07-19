# frozen_string_literal: true

require 'rails_helper'

# More information about action cable testing:
# https://github.com/palkan/action-cable-testing?tab=readme-ov-file
# https://guides.rubyonrails.org/testing.html#testing-action-cable

# This are some example specs for testing a channel

RSpec.describe MessagesChannel do
  let(:user) { create(:user) }
  let(:receiver) { create(:user) }

  before do
    # initialize connection with identifiers
    stub_connection current_user: user
  end

  describe '#subscribe' do
    it 'rejects the subscription without receiver_email' do
      subscribe
      expect(subscription).to be_rejected
    end

    it 'subscribes to a stream when receiver_email is provided' do
      subscribe(receiver_email: receiver.email)

      expect(subscription).to be_confirmed

      conversation_id = UsersConversation.find_conversation_id(user, receiver)

      expect(subscription).to have_stream_from("conversation_#{conversation_id}")
    end
  end

  describe '#receive' do
    it 'performs a broadcast when receiving a message' do
      subscribe(receiver_email: receiver.email)
      conversation_id = UsersConversation.find_conversation_id(user, receiver)
      expect { perform :receive, { body: 'hello' } }.to have_broadcasted_to("conversation_#{conversation_id}")
    end
  end

end
