require 'spec_helper'

describe Classroom::Collection::Comments do

  after do
    Classroom::Database.clean!
  end

  describe 'post /courses/:course/comments' do
    let(:comment_json) {{exercise_id: 1, submission_id: 1, comment: {content: 'hola', type: 'good'}}.to_json}

    context 'when authenticated' do
      before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_comments) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/comments', comment_json }

      let(:comment) { Classroom::Collection::Comments.for('bar').find_by(submission_id: 1) }

      it { expect(comment.to_json).to eq(comment_json)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/comments', comment_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/bar'}.to_json) }
    end

  end

  describe 'get /courses/:course/comments/:exercise_id' do
    let(:comment1) { {exercise_id: 1, submission_id: 1, comment: {content: 'hola', type: 'bad'}} }
    let(:comment2) { {exercise_id: 1, submission_id: 2, comment: {content: 'hola', type: 'good'}} }
    let(:comment3) { {exercise_id: 2, submission_id: 3, comment: {content: 'hola', type: 'warning'}} }

    before do
      Classroom::Collection::Comments.for('baz').insert!(comment1.wrap_json)
      Classroom::Collection::Comments.for('baz').insert!(comment2.wrap_json)
      Classroom::Collection::Comments.for('baz').insert!(comment3.wrap_json)
    end

    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('example/baz') }
      before { get '/courses/baz/comments/1' }

      it { expect(last_response.body).to eq({comments: [comment1, comment2]}.to_json)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/baz') }
      before { get '/courses/baz/comments/1' }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/baz'}.to_json) }
    end

  end
end
