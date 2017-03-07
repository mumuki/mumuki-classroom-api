require 'spec_helper'

describe Assignment do

  def with_course(json)
    {organization: 'example', course: 'example/k2048'}.merge(json)
  end

  before do
    Organization.create!(locale: 'es', name: 'example')
  end

  let(:except_fields) { {except: [:created_at, :updated_at, :_id]} }

  describe 'get' do
    let(:progress1) { {
      guide: {slug: 'example/foo'},
      student: {name: 'jondoe', email: 'jondoe@gmail.com', uid: 'github|123456'},
      exercise: {eid: 177, name: 'foo'},
      submissions: [{status: :passed}]} }

    let(:progress2) { {
      guide: {slug: 'example/foo'},
      student: {name: 'jondoe', email: 'jondoe@gmail.com', uid: 'github|123456'},
      exercise: {eid: 178, name: 'foo'},
      submissions: [{status: :failed, expectation_results: [{binding: 'f', inspection: 'HasComposition', result: 'failed'}]}, {status: :passed}]} }
    let(:progress3) { {
      guide: {slug: 'example/foo'},
      student: {name: 'jondoe', email: 'jondoe@gmail.com', uid: 'github|123456'},
      exercise: {eid: 178, name: 'foo'},
      submissions: [{status: :failed, expectation_results: [{binding: 'f', inspection: 'HasComposition', result: 'failed'}]}, {status: :passed}]} }
    let(:processed_submissions) { [{status: :failed, expectation_results: [{html: '<strong>f</strong> debe usar composición', result: 'failed'}]}, {status: :passed}] }


    before { Assignment.create! progress1.merge(organization: 'example', course: 'example/k2048') }
    before { Assignment.create! progress2.merge(organization: 'example', course: 'example/k2048') }
    before { Assignment.create! progress3.merge(organization: 'example', course: 'example/k1024') }

    before { header 'Authorization', build_auth_header('*') }

    context 'get /courses/:course/guides/:organization/:repository/:student_id' do
      before { get '/courses/k2048/guides/example/foo/github%7c123456' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({exercise_student_progress: [with_course(progress1), with_course(progress2.merge(submissions: processed_submissions))]}, except_fields) }
    end

    context '/courses/:course/guides/:organization/:repository/:student_id/:exercise_id' do
      before { get '/courses/k1024/guides/example/foo/github%7c123456/178' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like(with_course(progress3.merge(submissions: processed_submissions, course: 'example/k1024')), except_fields) }
    end
  end


end
