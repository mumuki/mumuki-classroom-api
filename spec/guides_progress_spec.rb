require 'spec_helper'

describe Classroom::Collection::Courses do

  before do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/guides/:org/:repo' do

    let(:guide_progress1) {{
      guide: { slug: 'example/foo' },
      student: { first_name: 'jon' },
      stats: { passed: 0, warnings: 0, failed: 1 },
      last_assignment: { exercise: { id: 1}, submission: {status: :failure} }
    }}

    let(:guide_progress2) {{
      guide: { slug: 'example/foo' },
      student: { first_name: 'bar' },
      stats: { passed: 1, warnings: 0, failed: 0 },
      last_assignment: { exercise: { id: 2}, submission: {status: :passed} }
    }}

    let(:guide_progress3) {{
      guide: { slug: 'example/bar' },
      student: { first_name: 'baz' },
      stats: { passed: 0, passed_with_warnings: 1, failed: 0 },
      last_assignment: { exercise: { id: 1}, submission: {status: :passed_with_warnings} }
    }}

    before { Classroom::Collection::GuideStudentsProgress.for('k2048').insert!(guide_progress1.wrap_json) }
    before { Classroom::Collection::GuideStudentsProgress.for('k2048').insert!(guide_progress2.wrap_json) }
    before { Classroom::Collection::GuideStudentsProgress.for('k2048').insert!(guide_progress3.wrap_json) }
    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/courses/k2048/guides/example/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({ guide_students_progress: [guide_progress1,
                                                                        guide_progress2]}.to_json) }
    end

  end

end
