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

  let(:assignment1) { {
    guide: { slug: 'example.org/foo' },
    student: {uid: 'agus@mumuki.org', first_name: 'foo', last_name: 'bar', email: 'agus@mumuki.org'},
    submissions: [ { status: 'passed'} ],
    exercise: { eid: 1}
  } }

  let(:assignment2) { {
    guide: { slug: 'example.org/foo' },
    student: {uid: 'agus@mumuki.org', first_name: 'foo', last_name: 'bar', email: 'agus@mumuki.org'},
    submissions: [ { status: 'failed'} ],
    exercise: { eid: 2}
  } }

  let(:assignment3) { {
    guide: { slug: 'example.org/foo' },
    student: {uid: 'agus@mumuki.org', first_name: 'foo', last_name: 'bar', email: 'agus@mumuki.org'},
    submissions: [ { status: 'passed'} ],
    exercise: { eid: 3}
  } }

  let(:empty_exercises) { {exercises: []}.to_json }
  let(:exercises_data) { {
    exercises: [
      {id: 1, tag_list: %w(ex1_a ex1_b)},
      {id: 2, tag_list: %w(ex2_a ex2_b), language: 'e2_lang'},
      {id: 3, tag_list: %w(ex3_a ex3_b), language: 'e3_lang'}
    ],
    language: 'guide_language'
  }.to_json }

  before { Mumuki::Classroom::GuideProgress.create! guide_progress1.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { Mumuki::Classroom::GuideProgress.create! guide_progress2.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { Mumuki::Classroom::GuideProgress.create! guide_progress3.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { Mumuki::Classroom::Assignment.create! assignment1.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { Mumuki::Classroom::Assignment.create! assignment2.merge(organization: 'example.org', course: 'example.org/k2048') }
  before { Mumuki::Classroom::Assignment.create! assignment3.merge(organization: 'example.org', course: 'example.org/k2048') }

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

    context 'with not_failed_assignments as query criteria' do
      let(:guide_progress1_with_total) { guide_progress1.deep_merge({stats: {not_failed: 4}}) }
      before { get '/courses/k2048/guides/example.org/foo?q=3&query_criteria=not_failed_assignments' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1_with_total)]}, except_fields) }
    end

    context 'with not_failed_assignments as query criteria and less_than as query options' do
      let(:guide_progress2_with_total) { guide_progress2.deep_merge({stats: {not_failed: 2}}) }
      before { get '/courses/k2048/guides/example.org/foo?q=3&query_criteria=not_failed_assignments&query_operand=less_than' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress2_with_total)]}, except_fields) }
    end

    context 'with not_failed_assignments as query criteria and close_to as query options' do
      let(:guide_progress2_with_total) { guide_progress2.deep_merge({stats: {not_failed: 2}}) }
      let(:guide_progress1_with_total) { guide_progress1.deep_merge({stats: {not_failed: 4}}) }
      before { get '/courses/k2048/guides/example.org/foo?q=3&query_criteria=not_failed_assignments&query_operand=close_to' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1_with_total),
                                                                              with_course(guide_progress2_with_total)]}, except_fields) }
    end

    context 'with total_assignments as query criteria' do
      context 'when it passes the filter' do
        let(:guide_progress3_with_total) { guide_progress3.deep_merge({stats: {total: 1}}) }
        before { get '/courses/k2048/guides/example.org/bar?query_criteria=total_assignments&query_operand=less_than&q=2' }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress3_with_total)]}, except_fields) }
      end

      context 'when it doesnt pass the filter' do
        before { get '/courses/k2048/guides/example.org/bar?query_criteria=total_assignments&query_operand=more_than&q=4' }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_like({guide_students_progress: []}, except_fields) }
      end
    end

    context 'with solved_assignments_percentage as query criteria' do
      let(:guide_progress1_with_total) { guide_progress1.deep_merge({stats: {solved_percentage: 100}}) }
      let(:guide_progress2_with_total) { guide_progress2.deep_merge({stats: {solved_percentage: 66.66666666666666}}) }

      context 'with more_than as query option' do
        before { get '/courses/k2048/guides/example.org/foo?query_criteria=solved_assignments_percentage&query_operand=more_than&q=50' }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1_with_total), with_course(guide_progress2_with_total)]}, except_fields) }
      end

      context 'with less_than as query option' do
        before { get '/courses/k2048/guides/example.org/foo?query_criteria=solved_assignments_percentage&query_operand=less_than&q=70' }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress2_with_total)]}, except_fields) }
      end
    end
  end

  describe 'get /courses/:course/guides/:org/:repo/report' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { post '/courses/k2048/guides/example.org/foo/report', empty_exercises }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count,items_to_review
bar,foo,agus@mumuki.org,2,2,0,""
doe,john,john@gmail.com,2,0,1,""
TEST
      end
    end

    context 'when it is filtered by student search' do
      before { post '/courses/k2048/guides/example.org/foo/report?q=john', empty_exercises }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count,items_to_review
doe,john,john@gmail.com,2,0,1,""
TEST
      end
    end

    context 'when it is filtered by not failed assignments' do
      before { post '/courses/k2048/guides/example.org/foo/report?q=4&query_criteria=not_failed_assignments', empty_exercises }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count,items_to_review
bar,foo,agus@mumuki.org,2,2,0,""
TEST
      end
    end

    context 'when exercises data is provided' do
      before { post '/courses/k2048/guides/example.org/foo/report', exercises_data }

      it do
        expect(last_response.body).to eq <<TEST
last_name,first_name,email,passed_count,passed_with_warnings_count,failed_count,items_to_review
bar,foo,agus@mumuki.org,2,2,0,"ex2_a, ex2_b, e2_lang"
doe,john,john@gmail.com,2,0,1,"ex1_a, ex1_b, guide_language, ex2_a, ex2_b, e2_lang, ex3_a, ex3_b, e3_lang"
TEST
      end
    end
  end

  describe 'get /api/courses/:course/students/:uid' do

    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progress exist' do
      before { get '/api/courses/k2048/students/agus@mumuki.org' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guide_students_progress: [with_course(guide_progress1),
                                                                              with_course(guide_progress3)]}, except_fields) }
    end

  end

end
