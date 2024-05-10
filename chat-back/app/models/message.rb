# frozen_string_literal: true

# Message model
class Message < ApplicationRecord
  belongs_to :user
  belongs_to :conversation
end
