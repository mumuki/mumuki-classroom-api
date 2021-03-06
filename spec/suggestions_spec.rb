require 'spec_helper'

describe 'suggestions', workspaces: [:organization] do

  def create_suggestion!(data)
    Mumuki::Classroom::Suggestion.create!(data.merge(sender: 'github|123456', email: 'foo@mumuki.org', guide_slug: 'mumukiproject/foo'))
  end

  describe '/suggestions/:organization/:repository/:exercise_id' do
    let(:message_to_post) { {uid: '1', exercise_id: 2, submission_id: '3', message: message}.to_json }

    before { create_suggestion!(content: 'Wrong arity.', exercise: {eid: 3}, submissions: [{sid: 4}]) }
    before { create_suggestion!(content: 'Check the arity of the `foo` function.', exercise: {eid: 3}, submissions: [{sid: 1}, {sid: 2}, {sid: 3}]) }
    before { create_suggestion!(content: 'Delegate!', exercise: {eid: 2}) }


    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('*') }
      before { get '/suggestions/mumukiproject/foo/3' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like(
                                           {suggestions: [
                                             {content: 'Check the arity of the `foo` function.',
                                              content_html: "<p>Check the arity of the <code>foo</code> function.</p>\n",
                                              times_used: 3},
                                             {content: 'Wrong arity.',
                                              content_html: "<p>Wrong arity.</p>\n",
                                              times_used: 1}]},
                                           {only: [:content, :content_html, :times_used]}) }
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { get '/suggestions/mumukiproject/foo/3' }

      it { expect(last_response.body).to json_like message: 'Unauthorized access to example.org/_ as teacher. Scope is ``' }
    end

  end

end
