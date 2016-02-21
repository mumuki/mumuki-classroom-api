require 'spec_helper'

require_relative '../app/routes'

describe 'routes' do
  def app
    Sinatra::Application
  end

  after do
    Classroom::Database.clean!
  end

  describe 'post /events/submissions' do
    let(:submission) {
      {status: :passed,
       result: 'all right',
       expectation_results: nil,
       feedback: nil,
       test_results: nil,
       submissions_count: 2,
       exercise: {
           id: 10,
           name: 'First Steps 1',
           number: 1},
       guide: {
           slug: 'pdep-utn/foo',
           name: 'Foo',
           language: {name: 'haskell'}},
       submitter: {
           social_id: 'github|gh1234',
           name: 'foo',
           email: nil,
           image_url: nil},
       id: 'abcd1234',
       content: 'x = 2'}.to_json }

    context 'when student exists' do
      before do
        Classroom::CourseStudent.insert!(
            student: {first_name: 'Jon', last_name: 'Doe', social_id: 'github|gh1234'},
            course: {slug: 'example/foo'})
      end

      before { post '/events/submissions', submission }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
    end
    context 'when student does not exist' do
      before { post '/events/submissions', submission }

      it { expect(last_response.status).to eq 400}
      it { expect(last_response.body).to json_eq message: 'Unknown course student {"student.social_id"=>"github|gh1234"}' }
    end
  end

  describe 'get /courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      before { Classroom::Course.insert!(name: 'foo', slug: 'test/foo', description: 'baz') }
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [{name: 'foo', slug: 'test/foo', description: 'baz'}] }
    end
  end

  describe 'post /courses' do
    let(:course_json) { {name: 'my-new-course',
                         description: 'haskell'}.to_json }
    let(:created_slug) { Classroom::Course.find_by(name: 'my-new-course')['slug'] }

    context 'when is normal teacher' do
      it 'rejects course creation' do
        header 'Authorization', build_auth_header('test/my-course')

        post '/courses', course_json

        expect(last_response).to_not be_ok
        expect(Classroom::Course.count).to eq 0
      end
    end

    context 'when is org admin' do
      before { header 'Authorization', build_auth_header('example/*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example/my-new-course' }
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example/my-new-course' }
    end

    context 'when course already exists' do
      before { Classroom::Course.insert!(name: 'my-new-course', slug: 'example/my-new-course') }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to_not be_ok }
      it { expect(last_response.body).to json_eq message: 'example/my-new-course does already exist' }

    end
  end

  describe 'post /courses/:course/students/' do
    let(:student_json) { {first_name: 'Jon', last_name: 'Doe'}.to_json }

    context 'when course exists' do
      before { Classroom::Course.insert!(name: 'foo', slug: 'example/foo') }

      context 'when not authenticated' do
        before { post '/courses/foo/students', student_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Classroom::CourseStudent.count).to eq 0 }
      end

      context 'when authenticated' do
        let(:created_course_student) { Classroom::CourseStudent.first.to_h.deep_symbolize_keys }
        before { header 'Authorization', build_auth_header('*') }
        before { post '/courses/foo/students', student_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_eq status: 'created' }
        it { expect(Classroom::CourseStudent.count).to eq 1 }
        it { expect(created_course_student).to eq(student: {first_name: 'Jon', last_name: 'Doe', social_id: 'github|user123456'},
                                                  course: {slug: 'example/foo'}) }
      end
    end

    context 'when course does not exist' do
      it 'rejects creating a student' do
        header 'Authorization', build_auth_header('*')

        post '/courses/foo/students', student_json

        expect(last_response).to_not be_ok
        expect(Classroom::CourseStudent.count).to eq 0
      end
    end
  end
end
