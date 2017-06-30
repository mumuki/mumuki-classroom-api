require 'spec_helper'

describe 'suggestions' do

  describe '/suggestions/:organization/:repository/:exercise_id' do
    let(:message_to_post) { {uid: '1', exercise_id: 2, submission_id: '3', message: message}.to_json }

    before { Suggestion.create!(content: 'Check the arity of the `foo` function.', sender: 'github|123456', email: 'foo@mumuki.org', guide_slug: 'mumukiproject/foo', exercise: {eid: 3}) }
    before { Suggestion.create!(content: 'Delegate!', sender: 'github|123456', email: 'foo@mumuki.org', guide_slug: 'mumukiproject/foo', exercise: {eid: 2}) }

    before { header 'Authorization', build_auth_header('*') }

    context 'when authenticated' do
      before { get '/suggestions/mumukiproject/foo/3' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like([{content: 'Check the arity of the `foo` function.'}], only: [:content]) }
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { get '/suggestions/mumukiproject/foo/3' }

      it { expect(last_response.body).to json_like message: 'Unauthorized access to example/_ as teacher. Scope is ``' }
    end

  end

end
