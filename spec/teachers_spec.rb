require 'spec_helper'

describe Classroom::Collection::Teachers do

  after do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/teachers' do

    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    let(:teacher) {{ email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', social_id: 'auth0|1' }}
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Classroom::Collection::Teachers.for('foo').insert!(teacher.wrap_json) }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq teachers: [teacher.merge(created_at: 'created_at')] }
    end

  end

  describe 'post /courses/:course/teachers' do
    let(:auth0) {double('auth0')}
    before { allow(Mumukit::Auth::User).to receive(:from_email).and_return(auth0) }
    before { allow(auth0).to receive(:social_id).and_return('auth|0') }
    before { allow(auth0).to receive(:add_permission!) }
    before { allow(auth0).to receive(:user).and_return(extra_data) }
    let(:extra_data) { { social_id: 'auth|0', picture: 'url' }.stringify_keys }
    let(:teacher) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com'} }
    let(:teacher_json) { teacher.to_json }

    context 'when course exists' do
      before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo'}.wrap_json) }

      context 'when not authenticated' do
        before { post '/courses/foo/teachers', teacher_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Classroom::Collection::Teachers.for('foo').count).to eq 0 }
      end

      context 'when authenticated' do
        before { header 'Authorization', build_auth_header('*') }
        before { post '/courses/foo/teachers', teacher_json }

        context 'and user does not exist' do
          let(:created_teacher) { Classroom::Collection::Teachers.for('foo').find_by({}).as_json }
          let(:created_at) { 'created_at' }
          before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_eq status: 'created' }
          it { expect(Classroom::Collection::Teachers.for('foo').count).to eq 1 }
          it { expect(created_teacher.deep_symbolize_keys).to eq(teacher.merge(created_at: created_at, image_url: 'url', social_id: 'auth|0')) }
        end
        context 'and teacher already exists by social_id' do
          before { post '/courses/foo/teachers', teacher_json }

          it { expect(last_response).to_not be_ok }
          it { expect(last_response.status).to eq 400 }
          it { expect(last_response.body).to json_eq(message: 'Teacher already exist') }
        end
        context 'and user already exists by email' do
          before { header 'Authorization', build_auth_header('*', 'auth1') }
          before { post '/courses/foo/teachers', teacher_json }

          it { expect(last_response).to_not be_ok }
          it { expect(last_response.status).to eq 400 }
          it { expect(last_response.body).to json_eq(message: 'Teacher already exist') }
        end
      end
    end

    context 'when course does not exist' do
      it 'rejects creating a teacher' do
        header 'Authorization', build_auth_header('*')

        post '/courses/foo/teachers', teacher_json

        expect(last_response).to_not be_ok
        expect(Classroom::Collection::Teachers.for('foo').count).to eq 0
      end
    end
  end



end
