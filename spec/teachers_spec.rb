require 'spec_helper'

describe Classroom::Collection::Teachers do

  before do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/teachers' do

    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', uid: 'auth0|1'} }
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Classroom::Collection::Teachers.for('foo').insert!(teacher.wrap_json) }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq teachers: [teacher.merge(created_at: 'created_at')] }
    end

  end

  describe 'post /courses/:course/teachers' do

    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo', uid: 'example/foo'}.wrap_json) }
    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar'} }
    before { allow(Mumukit::Nuntius::EventPublisher).to receive(:publish) }

    context 'when success' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to be_ok }
      it { expect(Classroom::Collection::Teachers.for('foo').count).to eq 1 }
      it { expect(Classroom::Collection::Teachers.for('foo').first_by({uid: 'foobar@gmail.com'}, {}).to_json).to json_eq(teacher.merge(uid: 'foobar@gmail.com', created_at: 'created_at')) }
    end

    context 'when no permissions' do
      before { header 'Authorization', build_auth_header('') }
      before { post '/courses/foo/teacher', teacher.to_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Classroom::Collection::Teachers.for('foo').count).to eq 0 }
    end

  end

end
