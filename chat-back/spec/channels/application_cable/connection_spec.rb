# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  let(:user) { create(:user) }
  let(:env)  { instance_double('env') }

  # Warden is not loaded in tests for channels, so we stub the environment and warden into the connection
  before do
    allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return(env)
    allow(env).to receive(:[]).with('warden').and_return(warden)
  end

  context 'when user is logged in' do
    let(:warden) { instance_double(Warden::Proxy, user:) }

    it 'successfully connects' do
      connect '/cable'
      expect(connection.current_user).to eq(user)
    end
  end

  context 'when user is not logged in' do
    let(:warden) { instance_double(Warden::Proxy, user: nil) }

    it 'rejects the connection' do
      expect { connect '/cable' }.to have_rejected_connection
    end
  end
end
