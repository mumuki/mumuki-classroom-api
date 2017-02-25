require 'spec_helper'

describe 'comments' do

  before do
    Classroom::Database.clean!
  end

  describe 'post /courses/:course/comments' do
    let(:comment) { {content: 'hola', type: 'good'} }
    let(:comment_to_post) { {uid: '1', exercise_id: 1, submission_id: '1', comment: comment}.to_json }

    context 'when authenticated' do
      before { Assignment.create!({student: {uid: '1'}, exercise: {id: 1}, submissions: [{id: '1'}]}.merge organization: 'example', course: 'example/bar') }
      before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_comments) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/comments', comment_to_post }

      let(:exercise) { Assignment.first }

      it { expect(exercise.submissions.first.as_json).to json_like({id: '1', comments: [comment]}) }
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/comments', comment_to_post }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz as teacher. Scope is ``'}.to_json) }
    end

  end

end
