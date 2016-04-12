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
    let(:course_json) { {code: 'K2001',
                         days: %w(monday saturday),
                         period: '2016',
                         shifts: ['morning'],
                         description: 'haskell',
                         slug: 'example/2016-K2001'}.to_json }
    let(:created_slug) { Classroom::Course.find_by(slug: 'example/2016-K2001')['slug'] }

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
      it { expect(created_slug).to eq 'example/2016-K2001' }
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Course.count).to eq 1 }
      it { expect(created_slug).to eq 'example/2016-K2001' }
    end

    context 'when course already exists' do
      before { Classroom::Course.insert!(slug: 'example/2016-K2001') }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to_not be_ok }
      it { expect(last_response.body).to json_eq message: 'example/2016-K2001 does already exist' }

    end
  end

  describe 'get /courses/:course' do
    let(:guide_progress1) {{
      guide: { name: 'Bar', slug: 'pdep-utn/bar', language: { name: 'haskell' } },
      course: { slug: 'example/foo' } }}

    let(:guide_progress2) {{
      guide: { name: 'Baz', slug: 'pdep-utn/baz', language: { name: 'haskell' } },
      course: { slug: 'example/foo' } }}

    let(:guide_progress3) {{
      guide: { name: 'Foo', slug: 'pdep-utn/foo', language: { name: 'haskell' } },
      course: { slug: 'example/test' } }}

    before { header 'Authorization', build_auth_header('*') }

    context 'when no guides in a course yet' do
      before { get '/courses/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq course_guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Classroom::GuideProgress.insert!(guide_progress1) }
      before { Classroom::GuideProgress.insert!(guide_progress2) }
      before { Classroom::GuideProgress.insert!(guide_progress3) }
      before { get '/courses/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq course_guides: [guide_progress1[:guide], guide_progress2[:guide]] }
    end

  end

  describe 'get /students/:course' do

    let(:student) {{ email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar' }}
    let(:course) {{ slug: 'example/foo' }}

    let(:guide_progress1) {{ student: student, course: course, guide: { slug: 'foo' } }}
    let(:guide_progress2) {{ student: student, course: course, guide: { slug: 'bar' } }}
    let(:guide_progress3) {{ student: student, course: { slug: 'example/test' }, guide: { slug: 'baz' } }}

    before { header 'Authorization', build_auth_header('*') }

    context 'when guides already exists in a course' do
      before { Classroom::GuideProgress.insert!(guide_progress1) }
      before { Classroom::GuideProgress.insert!(guide_progress2) }
      before { Classroom::GuideProgress.insert!(guide_progress3) }
      before { get '/students/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq students: [student] }
    end

  end

  describe 'get /guide_progress:course/:repo' do
    let(:guide_progress1) {{
      guide: { slug: 'example/foo' },
      course: { slug: 'example/k1024' } }}

    let(:guide_progress2) {{
      guide: { slug: 'example/foo' },
      course: { slug: 'example/k2048' } }}

    let(:guide_progress3) {{
      guide: { slug: 'example/foo' },
      course: { slug: 'example/k2048' } }}

    before { Classroom::GuideProgress.insert!(guide_progress1) }
    before { Classroom::GuideProgress.insert!(guide_progress2) }
    before { Classroom::GuideProgress.insert!(guide_progress3) }
    before { header 'Authorization', build_auth_header('*') }

    context 'when guide_progres exist' do
      before { get '/guide_progress/k2048/example/foo' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq({ guide: guide_progress2[:guide],
                                                   progress: [
                                                     { course: guide_progress2[:course] },
                                                     { course: guide_progress3[:course] }
                                                   ] }) }
    end

  end

  describe 'get /guide_progress/:repo/student_id/exercise_id' do
    let(:guide_progress1) {{
      guide: { slug: 'example/foo' },
      course: { slug: 'example/k1024' },
      student: { name: 'jondoe', email: 'jondoe@gmail.com', social_id: 'github|123456' },
      exercises: [ { id: 177 } ] }}

    let(:guide_progress2) {{
      guide: { slug: 'example/foo' },
      course: { slug: 'example/k2048' },
      student: { name: 'jondoe', email: 'jondoe@gmail.com', social_id: 'github|123456' },
      exercises: [ { id: 177 }, { id: 178 }, { id: 179 }, { id: 180 } ]}}

    before { Classroom::GuideProgress.insert!(guide_progress1) }
    before { Classroom::GuideProgress.insert!(guide_progress2) }
    before { header 'Authorization', build_auth_header('*') }

    context 'when student change course and sent an old exercise' do
      before { get '/guide_progress/k2048/example/foo/github%7c123456/177' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq({ exercise_progress: {
        guide: guide_progress2[:guide],
        course: guide_progress2[:course],
        student: guide_progress2[:student],
        exercise: guide_progress2[:exercises].first,
      }}) }
    end

    context 'when student change course and sent a new exercise' do
      before { get '/guide_progress/k2048/example/foo/github%7c123456/178' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq({ exercise_progress: {
        guide: guide_progress2[:guide],
        course: guide_progress2[:course],
        student: guide_progress2[:student],
        exercise: guide_progress2[:exercises].second,
      }}) }
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

  describe 'post /comment/foo/bar' do
    let(:comment_json) {{submission_id: 1, comment: {content: 'hola', type: 'good'}}.to_json}

    context 'when authenticated' do
      before { expect(Classroom::Rabbit).to receive(:publish_comments) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/comment/bar', comment_json }

      it { expect(Classroom::Comment.where(submission_id: 1).first.to_json).to eq(comment_json)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/comment/baz', comment_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/bar'}.to_json) }
    end

  end

  describe 'post /follower' do
    let(:follower_json) {{email: "aguspina87@gmail.com", course: "curso", social_id: "social|1"}.to_json}
    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/follower/bar', follower_json }

      it { expect(Classroom::Follower.where(course: "curso", email: "aguspina87@gmail.com").first.to_json).to eq({course: "curso",social_ids: ["social|1"]}.to_json)}
    end

    context 'when repeat follower' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/follower/bar', follower_json }
      before { post '/follower/bar', follower_json }

      it { expect(Classroom::Follower.where(course: "curso", email: "aguspina87@gmail.com").first["social_ids"].count).to eq(1)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/follower/baz', follower_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/bar'}.to_json) }
    end

    skip 'when not authenticated' do
      let(:follower_json) {{email: "aguspina87@gmail.com", course: "curso", social_id: "social|1"}.to_json}
      before { post '/follower', follower_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Classroom::Follower.count).to eq 0 }
    end

  end

  skip 'delete /follower' do
    let(:follower_json) {{email: "aguspina87@gmail.com", course: "curso", social_id: "social|1"}.to_json}
    before { header 'Authorization', build_auth_header('*') }
    before { post '/follower', follower_json }
    before { delete '/follower/curso/aguspina87@gmail.com/social%7c1', follower_json }

    it { expect(Classroom::Follower.count).to eq 0 }
  end
end
