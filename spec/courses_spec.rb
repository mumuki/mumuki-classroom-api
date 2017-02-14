require 'spec_helper'

describe Classroom::Collection::Courses do

  before do
    Classroom::Database.clean!
  end

  describe 'get /courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      before { Classroom::Collection::Courses.for('example').insert!({name: 'foo', slug: 'test/foo', uid: 'test/foo', description: 'baz'}) }
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [{name: 'foo', slug: 'test/foo', uid: 'test/foo', description: 'baz', organization: 'example'}] }
    end
  end

  describe 'post /courses' do
    let(:course_json) { {code: 'K2001',
                         days: %w(monday saturday),
                         period: '2016',
                         shifts: ['morning'],
                         description: 'haskell',
                         uid: 'example/2016-K2001',
                         slug: 'example/2016-K2001'}.to_json }
    let(:created_uid) { Classroom::Collection::Courses.for('example').find_by(uid: 'example/2016-K2001').uid }

    context 'when is normal teacher' do
      it 'rejects course creation' do
        header 'Authorization', build_auth_header('test/my-course')

        post '/courses', course_json

        expect(last_response).to_not be_ok
        expect(Classroom::Collection::Courses.for('example').count).to eq 0
      end
    end

    context 'when is org admin' do
      before { allow(Mumukit::Nuntius::EventPublisher).to receive(:publish) }
      before { header 'Authorization', build_auth_header('example/*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Collection::Courses.for('example').count).to eq 1 }
      it { expect(created_uid).to eq 'example/2016-K2001' }
    end

    context 'when is global admin' do
      before { allow(Mumukit::Nuntius::EventPublisher).to receive(:publish) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Collection::Courses.for('example').count).to eq 1 }
      it { expect(created_uid).to eq 'example/2016-K2001' }
    end

    context 'when course already exists' do
      before { Classroom::Collection::Courses.for('example').insert!({uid: 'example/2016-K2001'}.wrap_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to_not be_ok }
      it { expect(last_response.body).to json_eq message: 'example/2016-K2001 does already exist' }

    end
  end

  describe 'get courses/:course/progress' do
    let(:exercise_progress) { {student: {uid: 1}, guide: {slug: 'foo/bar'}, exercise: {id: 1}, submissions: []} }
    before { Classroom::Collection::ExerciseStudentProgress.for('foo').insert! exercise_progress.wrap_json }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/progress' }
    it { expect(last_response.body).to json_eq exercise_student_progress: [exercise_progress] }
  end

end
