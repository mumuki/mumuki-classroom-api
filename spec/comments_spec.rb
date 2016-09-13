require 'spec_helper'

describe Classroom::Comments do

  after do
    Classroom::Database.clean!
  end

  describe 'post /courses/:course/comments' do
    let(:comment) {{content: 'hola', type: 'good'}}
    let(:comment_to_post) {{social_id: 1, exercise_id: 1, submission_id: 1, comment: comment}.to_json}

    context 'when authenticated' do
      before { Classroom::Collection::ExerciseStudentProgress.for('bar').insert!({student: {social_id: 1}, exercise: {id: 1}, submissions: [{id:1}]}.wrap_json) }
      before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_comments) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/comments', comment_to_post }

      let(:exercise) { Classroom::Collection::ExerciseStudentProgress.for('bar').all.raw.first }

      it { expect(exercise.submissions.first.deep_symbolize_keys).to eq({id: 1, comments: [comment]})}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/comments', comment_to_post }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/bar'}.to_json) }
    end

  end

end
