require_relative '../spec/spec_helper'

describe Mumukit::Auth::Profile do
  describe '.extract' do
    let(:profile) { Mumukit::Auth::Profile.extract(foo: 1,
                                                   name: 'John Doe',
                                                   last_name: 'John Doe',
                                                   email: 'jonny@org.com') }

    context 'when different profiles' do
      let(:other_profile) { Mumukit::Auth::Profile.extract(foo: 10,
                                                           name: 'John Doe',
                                                           last_name: 'John Doe',
                                                           email: 'jonny@brandneworg.com') }

      it { expect(profile).to_not eq other_profile }
    end

    context 'when same profiles but with different non-significant data' do
      let(:other_profile) { Mumukit::Auth::Profile.extract(foo: 12,
                                                           name: 'John Doe',
                                                           last_name: 'John Doe',
                                                           email: 'jonny@org.com') }

      it { expect(profile).to eq other_profile }
    end
  end

end
