require 'spec_helper'

describe 'messages' do

  describe 'post /courses/:course/messages' do
    let(:message) { {content: 'hola'} }
    let(:message_to_post) { {uid: '1', exercise_id: 2, submission_id: '3', message: message}.to_json }

    context 'when authenticated' do
      before { Assignment.create!({student: {uid: '1'}, exercise: {eid: 2}, submissions: [{sid: '3'}]}.merge organization: 'example', course: 'example/bar') }
      before { expect(Mumukit::Nuntius).to receive(:notify!).with('messages', {message: message,
                                                                               submission_id: '3',
                                                                               exercise_id: 2,
                                                                               organization: 'example'}.as_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/messages', message_to_post }

      let(:exercise) { Assignment.last }

      it { expect(exercise.submissions.first.as_json).to json_like({sid: '3', messages: [content: "<p>hola</p>\n"]}, {except: [:_id, :date, :created_at, :updated_at]}) }
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/messages', message_to_post }

      it { expect(last_response.body).to json_like message: 'Unauthorized access to example/baz as teacher. Scope is ``' }
    end

  end

end
