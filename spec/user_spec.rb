require 'spec_helper'

describe User do
  context 'can not have a null or empty uid' do
    it { expect { User.create! uid: nil }.to raise_error Mongoid::Errors::Validations }
    it { expect { User.create! uid: '' }.to raise_error Mongoid::Errors::Validations }
  end
end
