require 'spec_helper'

describe 'comments' do

  before do
    Classroom::Database.clean!
  end

  describe 'post /courses/:course/comments' do
    let(:comment) { {content: 'hola', type: 'good'} }
    let(:comment_to_post) { {uid: '1', exercise_id: 2, submission_id: '3', comment: comment}.to_json }

    context 'when authenticated' do
      before { Assignment.create!({student: {uid: '1'}, exercise: {eid: 2}, submissions: [{sid: '3'}]}.merge organization: 'example', course: 'example/bar') }
      before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_comments).with({comment: comment,
                                                                                       submission_id: '3',
                                                                                       exercise_id: 2,
                                                                                       tenant: 'example'}.as_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/comments', comment_to_post }

      let(:exercise) { Assignment.last }

      it { expect(exercise.submissions.first.as_json).to json_like({sid: '3', comments: [comment]}, {except: [:_id, :date]}) }
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/comments', comment_to_post }

      it { expect(last_response.body).to json_like message: 'Unauthorized access to example/baz as teacher. Scope is ``' }
    end

  end

end
