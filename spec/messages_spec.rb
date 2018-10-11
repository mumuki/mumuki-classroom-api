require 'spec_helper'

describe 'messages' do

  describe 'post /courses/:course/messages' do
    let(:message_to_post) { {uid: '1', exercise_id: 2, submission_id: '3', message: message, guide_slug: 'mumukiproject/example'}.to_json }

    context 'when authenticated' do
      let(:exercise) { {eid: 2} }
      before { Assignment.create!({student: {uid: '1'}, exercise: exercise, guide: {slug: 'mumukiproject/example'}, submissions: [{sid: '3'}]}.merge organization: 'example.org', course: 'example.org/bar') }
      before { Assignment.create!({student: {uid: '1'}, exercise: exercise, guide: {slug: 'mumukiproject/test'}, submissions: [{sid: '4'}]}.merge organization: 'example.org', course: 'example.org/bar') }
      before { expect(Mumuki::Classroom::Nuntius).to receive(:notify!).with('teacher-messages', {message: message,
                                                                                       submission_id: '3',
                                                                                       exercise_id: 2,
                                                                                       organization: 'example.org'}.as_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/messages', message_to_post }

      let(:assignment) { Assignment.find_by(organization: 'example.org', course: 'example.org/bar', 'exercise.eid': 2, 'guide.slug': 'mumukiproject/example', 'student.uid': '1') }
      context 'when content' do
        let(:message) { {content: 'hola', sender: 'github|123456'} }
        it { expect(assignment.submissions.first.as_json).to json_like({sid: '3', messages: [content: "<p>hola</p>\n", sender: 'github|123456']}, {except: [:_id, :date, :created_at, :updated_at]}) }

        context 'creates a new suggestion' do
          let(:suggestion) { Suggestion.last }
          it { expect(suggestion.times_used).to eq 1 }
          it { expect(suggestion.guide_slug).to eq 'mumukiproject/example' }
          it { expect(suggestion.exercise.as_json).to json_like exercise }
        end

        context 'updates existing suggestion when used' do
          let(:message_from_suggestion_to_post) { {uid: '2', exercise_id: 2, submission_id: '5', message: message, guide_slug: 'mumukiproject/example', suggestion_id: Suggestion.last.id}.to_json }

          before { Assignment.create!({student: {uid: '2'}, exercise: exercise, guide: {slug: 'mumukiproject/example'}, submissions: [{sid: '5'}]}.merge organization: 'example.org', course: 'example.org/bar') }

          before { expect(Mumuki::Classroom::Nuntius).to receive(:notify!).with('teacher-messages', {message: message,
                                                                                           submission_id: '5',
                                                                                           exercise_id: 2,
                                                                                           organization: 'example.org'}.as_json) }

          before { post '/courses/bar/messages', message_from_suggestion_to_post }


          it { expect(Suggestion.count).to eq 1 }
          it { expect(Suggestion.last.times_used).to eq 2 }
        end
      end

      context 'when no content' do
        let(:message) { {content: nil, sender: 'github|123456'} }
        it { expect(assignment.submissions.first.as_json).to json_like({sid: '3', messages: [sender: 'github|123456']}, {except: [:_id, :date, :created_at, :updated_at]}) }
        it { expect(assignment.threads(:ruby).as_json.first).to json_like({status: nil, content: "<div class=\"highlight\"><pre class=\"highlight ruby\"><code>\n</code></pre></div>", messages: [{sender: 'github|123456'}]}, {except: [:_id, :created_at, :updated_at]}) }
      end
    end

    context 'reject unauthorized requests' do
      let(:message) { {content: 'hola', sender: 'github|123456'} }
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/messages', message_to_post }

      it { expect(last_response.body).to json_like message: 'Unauthorized access to example.org/baz as teacher. Scope is ``' }
    end

  end

end
