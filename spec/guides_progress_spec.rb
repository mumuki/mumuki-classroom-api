require 'spec_helper'

describe Classroom::Collection::Courses do

  def with_course(json)
    {organization: 'example', course: 'example/k2048'}.merge(json)
  end

  before do
    Classroom::Database.clean!
  end

  let(:guide_progress1) { {
    guide: {slug: 'example/foo'},
    student: {first_name: 'jon'},
    stats: {passed: 0, warnings: 0, failed: 1},
    last_assignment: {exercise: {id: 1}, submission: {status: :failure}}
  } }

  let(:guide_progress2) { {
    guide: {slug: 'example/foo'},
    student: {uid: 'agus@mumuki.org'},
    stats: {passed: 1, warnings: 0, failed: 0},
    last_assignment: {exercise: {id: 2}, submission: {status: :passed}}
  } }

  let(:guide_progress3) { {
    guide: {slug: 'example/bar'},
    student: {uid: 'agus@mumuki.org'},
    stats: {passed: 0, passed_with_warnings: 1, failed: 0},
    last_assignment: {exercise: {id: 1}, submission: {status: :passed_with_warnings}}
  } }

  before { Classroom::Collection::GuideStudentsProgress.for('example', 'k2048').insert!(guide_progress1) }
  before { Classroom::Collection::GuideStudentsProgress.for('example', 'k2048').insert!(guide_progress2) }
  before { Classroom::Collection::GuideStudentsProgress.for('example', 'k2048').insert!(guide_progress3) }

  describe 'get /courses/:course/guides/:org/:repo' do

    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/courses/k2048/guides/example/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({guide_students_progress: [with_course(guide_progress1),
                                                                       with_course(guide_progress2)]}.to_json) }
    end

  end

  describe 'get /api/courses/:course/students/:uid' do

    before { header 'Authorization', build_mumuki_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/api/courses/k2048/students/agus@mumuki.org' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({guide_students_progress: [with_course(guide_progress2),
                                                                       with_course(guide_progress3)]}.to_json) }
    end

  end

end
