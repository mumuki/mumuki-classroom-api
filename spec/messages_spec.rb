require 'spec_helper'

describe 'messages' do

  describe 'post /courses/:course/messages' do
    let(:message_to_post) { {uid: '1', exercise_id: 2, submission_id: '3', message: message}.to_json }

    context 'when authenticated' do
      before { Assignment.create!({student: {uid: '1'}, exercise: {eid: 2}, submissions: [{sid: '3'}]}.merge organization: 'example', course: 'example/bar') }
      before { expect(Mumukit::Nuntius).to receive(:notify!).with('teacher-messages', {message: message,
                                                                                       submission_id: '3',
                                                                                       exercise_id: 2,
                                                                                       organization: 'example'}.as_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/messages', message_to_post }

      let(:exercise) { Assignment.last }
      context 'when content' do
        let(:message) { {content: 'hola', sender: 'github|123456'} }
        it { expect(exercise.submissions.first.as_json).to json_like({sid: '3', messages: [content: "<p>hola</p>\n", sender: 'github|123456']}, {except: [:_id, :date, :created_at, :updated_at]}) }
      end
      context 'when no content' do
        let(:message) { {content: nil, sender: 'github|123456'} }
        it { expect(exercise.submissions.first.as_json).to json_like({sid: '3', messages: [sender: 'github|123456']}, {except: [:_id, :date, :created_at, :updated_at]}) }
        it { expect(exercise.threads(:ruby).as_json.first).to json_like({status: nil, content: "<pre class=\"highlight ruby\"><code>\n</code></pre>", messages: [{sender: 'github|123456'}]}, {except: [:_id, :created_at, :updated_at]}) }
      end
    end

    context 'reject unauthorized requests' do
      let(:message) { {content: 'hola', sender: 'github|123456'} }
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/messages', message_to_post }

      it { expect(last_response.body).to json_like message: 'Unauthorized access to example/baz as teacher. Scope is ``' }
    end

  end

end
