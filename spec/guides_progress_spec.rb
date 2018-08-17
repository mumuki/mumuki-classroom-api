require 'spec_helper'

describe Course do

  def with_course(json)
    {organization: 'example.org', course: 'example.org/k2048'}.merge json
  end

  let(:except_fields) { {except: [:created_at, :updated_at, :page, :total]} }

  let(:guide_progress1) { {
    guide: {slug: 'example.org/foo'},
    student: {uid: 'agus@mumuki.org', first_name: 'foo', last_name: 'bar', email: 'agus@mumuki.org'},
    stats: {passed: 2, passed_with_warnings: 2, failed: 0},
    last_assignment: {exercise: {eid: 2}, submission: {status: :passed}}
  } }

  let(:guide_progress2) { {
    guide: {slug: 'example.org/foo'},
    student: {uid: 'john@gmail.com', first_name: 'john', last_name: 'doe', email: 'john@gmail.com'},
    stats: {passed: 2, passed_with_warnings: 0, failed: 1},
    last_assignment: {exercise: {eid: 1}, submission: {status: :failure}}
  } }

  let(:guide_progress3) { {
    guide: {slug: 'example.org/bar'},
    student: {uid: 'agus@mumuki.org', first_name: 'foo', last_name: 'bar', email: 'agus@mumuki.org'},
    stats: {passed: 0, passed_with_warnings: 1, failed: 0},
    last_assignment: {exercise: {eid: 1}, submission: {status: :passed_with_warnings}}
  } }

  before { GuideProgress.create! guide_progress1.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { GuideProgress.create! guide_progress2.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { GuideProgress.create! guide_progress3.merge(organization: 'example.org', course: 'example.org/k2048') }

  describe 'get /courses/:course/guides/:org/:repo' do

    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/courses/k2048/guides/example.org/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1),
                                                                              with_course(guide_progress2)]}, except_fields) }
    end

    context 'with a student query' do
      before { get '/courses/k2048/guides/example.org/foo?q=john' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress2)]}, except_fields) }
    end

    context 'with not failed assignments query' do
      let(:guide_progress1_with_total) { guide_progress1.deep_merge({stats: {not_failed: 4}}) }
      before { get '/courses/k2048/guides/example.org/foo?q=3&query_criteria=not_failed_assignments' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1_with_total)]}, except_fields) }
    end

  end

  describe 'get /courses/:course/guides/:org/:repo/report' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/courses/k2048/guides/example.org/foo/report' }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count
bar,foo,agus@mumuki.org,2,2,0
doe,john,john@gmail.com,2,0,1
TEST
      end
    end

    context 'when it is filtered by student search' do
      before { get '/courses/k2048/guides/example.org/foo/report?q=john' }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count
doe,john,john@gmail.com,2,0,1
TEST
      end
    end

    context 'when it is filtered by not failed assignments' do
      before { get '/courses/k2048/guides/example.org/foo/report?q=4&query_criteria=not_failed_assignments' }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count
bar,foo,agus@mumuki.org,2,2,0
TEST
      end
    end
  end

  describe 'get /api/courses/:course/students/:uid' do

    before { header 'Authorization', build_mumuki_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/api/courses/k2048/students/agus@mumuki.org' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1),
                                                                              with_course(guide_progress3)]}, except_fields) }
    end

  end

end
