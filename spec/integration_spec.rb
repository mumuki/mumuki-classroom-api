require 'spec_helper'

require_relative '../app/routes'

describe 'routes' do
  def app
    Sinatra::Application
  end

  after do
    Classroom::Database.clean!
  end

  describe 'get /api/courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/api/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      before { Classroom::Course.insert!(name: 'foo', slug: 'test/foo', description: 'baz') }
      before { get '/api/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [{name: 'foo', slug: 'test/foo', description: 'baz'}] }
    end
  end

  describe 'post /api/courses' do
    let(:course_json) { {name: 'my-new-course',
                         description: 'haskell'}.to_json }
    let(:created_slug) { Classroom::Course.find_by(name: 'my-new-course')['slug'] }

    context 'when is normal teacher' do
      it 'rejects course creation' do
        header 'Authorization', build_auth_header('test/my-course')

        post '/api/courses', course_json

        expect(last_response).to_not be_ok
        expect(Classroom::Course.count).to eq 0
      end
    end

    context 'when is org admin' do
      before { header 'Authorization', build_auth_header('example/*') }
      before { post '/api/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example/my-new-course' }
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/api/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example/my-new-course' }
    end
  end

  describe 'post /api/courses/:course/students/' do
    let(:valid_student) { {name: 'Jon Doe'} }

    context 'when course exists' do
      before { Classroom::Course.insert!(name: 'foo', slug: 'test/foo') }

      context 'when not authenticated' do
        before { post '/api/courses/foo/students', valid_student }

        it { expect(last_response).to_not be_ok }
        it { expect(Classroom::CourseStudent.count).to eq 0 }
      end

      context 'when authenticated' do
        before { header 'Authorization', build_auth_header('*') }
        before { post '/api/courses/foo/students', valid_student }

        it { expect(last_response).to be_ok }
        it { expect(Classroom::CourseStudent.count).to eq 1 }
      end
    end

    context 'when course does not exist' do
      it 'rejects creating a student' do
        header 'Authorization', build_auth_header('*')

        post '/api/courses/foo/students', valid_student

        expect(last_response).to_not be_ok
        expect(Classroom::CourseStudent.count).to eq 0
      end
    end
  end
end
