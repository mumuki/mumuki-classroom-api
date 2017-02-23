require 'spec_helper'

describe Classroom::Collection::ExerciseStudentProgress do

  def with_course(json)
    {organization: 'example', course: 'example/k2048'}.merge(json)
  end

  before do
    Classroom::Database.clean!
  end

  before do
    Organization.create!(locale: 'es', name: 'example')
  end

  describe 'get' do
    let(:progress1) { {
      guide: {slug: 'example/foo'},
      student: {name: 'jondoe', email: 'jondoe@gmail.com', uid: 'github|123456'},
      exercise: {id: 177, name: 'foo'},
      submissions: [{status: :passed}]} }

    let(:progress2) { {
      guide: {slug: 'example/foo'},
      student: {name: 'jondoe', email: 'jondoe@gmail.com', uid: 'github|123456'},
      exercise: {id: 178, name: 'foo'},
      submissions: [{status: :failed, expectation_results: [{binding: 'f', inspection: 'HasComposition', result: 'failed'}]}, {status: :passed}]} }
    let(:result2) { {
      guide: {slug: 'example/foo'},
      student: {name: 'jondoe', email: 'jondoe@gmail.com', uid: 'github|123456'},
      exercise: {id: 178, name: 'foo'},
      submissions: [{status: :failed, expectation_results: [{html: '<strong>f</strong> debe usar composición', result: 'failed'}]}, {status: :passed}]} }


    before { Classroom::Collection::ExerciseStudentProgress.for('example', 'k2048').insert! progress1 }
    before { Classroom::Collection::ExerciseStudentProgress.for('example', 'k2048').insert! progress2 }
    before { header 'Authorization', build_auth_header('*') }

    context 'get /courses/:course/guides/:organization/:repository/:student_id' do
      before { get '/courses/k2048/guides/example/foo/github%7c123456' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({exercise_student_progress: [with_course(progress1), with_course(result2)]}.to_json) }
    end

    context '/courses/:course/guides/:organization/:repository/:student_id/:exercise_id' do
      before { get '/courses/k2048/guides/example/foo/github%7c123456/178' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq(with_course(result2).to_json) }
    end
  end


end
