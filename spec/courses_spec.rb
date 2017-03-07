require 'spec_helper'

describe Course do

  let(:except_fields) { {except: [:created_at, :updated_at, :_id]} }

  describe 'get /courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      let(:course) { {name: 'foo', slug: 'test/foo', uid: 'test/foo', description: 'baz', organization: 'example'} }
      before { Course.create!(course) }
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({courses: [course]}, except_fields) }
    end
  end

  describe 'post /courses' do
    let(:course) { {code: 'K2001',
                    days: %w(monday saturday),
                    period: '2016',
                    shifts: ['morning'],
                    description: 'haskell',
                    organization: 'example',
                    slug: 'example/2016-K2001'} }
    let(:created_uid) { Course.last.uid }

    context 'when is normal teacher' do
      context 'rejects course creation' do
        before { header 'Authorization', build_auth_header('test/my-course') }
        before { post '/courses', course.to_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Course.count).to eq 0 }
      end
    end

    context 'when is org admin' do
      before { header 'Authorization', build_auth_header('example/*') }
      before { post '/courses', course.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Course.count).to eq 1 }
      it { expect(created_uid).to eq 'example/2016-K2001' }
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course.to_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Course.count).to eq 1 }
      it { expect(created_uid).to eq 'example/2016-K2001' }
    end

    context 'when course already exists' do
      before { Course.create! course }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course.to_json }

      it { expect(Course.count).to eq 1 }
      it { expect(last_response).to_not be_ok }
      it { expect(last_response.status).to eq 422 }

    end
  end

  describe 'get courses/:course/progress' do
    let(:exercise_progress) { {student: {uid: '1'}, guide: {slug: 'foo/bar'}, exercise: {eid: 1}} }
    before { Assignment.create! exercise_progress.merge(organization: 'example', course: 'example/foo') }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/progress' }
    it { expect(last_response.body).to json_like({exercise_student_progress: [exercise_progress.merge(organization: 'example', course: 'example/foo')]}, except_fields) }
  end

end
