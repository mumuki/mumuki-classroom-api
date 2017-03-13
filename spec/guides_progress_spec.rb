require 'spec_helper'

describe Course do

  def with_course(json)
    {organization: 'example', course: 'example/k2048'}.merge json
  end

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  let(:guide_progress1) { {
    guide: {slug: 'example/foo'},
    student: {uid: 'agus@mumuki.org'},
    stats: {passed: 1, passed_with_warnings: 0, failed: 0},
    last_assignment: {exercise: {eid: 2}, submission: {status: :passed}}
  } }

  let(:guide_progress2) { {
    guide: {slug: 'example/foo'},
    student: {uid: 'jon@gmail.com'},
    stats: {passed: 0, passed_with_warnings: 0, failed: 1},
    last_assignment: {exercise: {eid: 1}, submission: {status: :failure}}
  } }

  let(:guide_progress3) { {
    guide: {slug: 'example/bar'},
    student: {uid: 'agus@mumuki.org'},
    stats: {passed: 0, passed_with_warnings: 1, failed: 0},
    last_assignment: {exercise: {eid: 1}, submission: {status: :passed_with_warnings}}
  } }

  before { GuideProgress.create! guide_progress1.merge(organization: 'example', course: 'example/k2048') }
  before { GuideProgress.create! guide_progress2.merge(organization: 'example', course: 'example/k2048') }
  before { GuideProgress.create! guide_progress3.merge(organization: 'example', course: 'example/k2048') }

  describe 'get /courses/:course/guides/:org/:repo' do

    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/courses/k2048/guides/example/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1),
                                                                              with_course(guide_progress2)]}, except_fields) }
    end

  end

  describe 'get /api/courses/:course/students/:uid' do

    before { header 'Authorization', build_mumuki_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/api/courses/k2048/students/agus@mumuki.org' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress3),
                                                                              with_course(guide_progress1)]}, except_fields) }
    end

  end

end
