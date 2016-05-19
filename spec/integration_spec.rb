require 'spec_helper'

require_relative '../app/routes'

describe 'routes' do
  def app
    Sinatra::Application
  end

  after do
    Classroom::Database.clean!
  end

  describe 'get /courses/' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when no courses yet' do
      before { get '/courses' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq courses: [] }
    end

    context 'when there are courses' do
      before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'test/foo', description: 'baz'}.wrap_json) }
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
    let(:created_slug) { Classroom::Collection::Courses.find_by(slug: 'example/2016-K2001').slug }

    context 'when is normal teacher' do
      it 'rejects course creation' do
        header 'Authorization', build_auth_header('test/my-course')

        post '/courses', course_json

        expect(last_response).to_not be_ok
        expect(Classroom::Collection::Courses.count).to eq 0
      end
    end

    context 'when is org admin' do
      before { header 'Authorization', build_auth_header('example/*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Collection::Courses.count).to eq 1 }
      it { expect(created_slug).to eq 'example/2016-K2001' }
    end

    context 'when is global admin' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq status: 'created' }
      it { expect(Classroom::Collection::Courses.count).to eq 1 }
      it { expect(created_slug).to eq 'example/2016-K2001' }
    end

    context 'when course already exists' do
      before { Classroom::Collection::Courses.insert!({slug: 'example/2016-K2001'}.wrap_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses', course_json }

      it { expect(last_response).to_not be_ok }
      it { expect(last_response.body).to json_eq message: 'example/2016-K2001 does already exist' }

    end
  end

  describe 'get /courses/:course/guides' do
    let(:haskell) {{ name: 'haskell', devicon: 'haskell' }}
    let(:guide1) {{ slug: 'pdep-utn/foo', name: 'Foo', language: haskell }}
    let(:guide2) {{ slug: 'pdep-utn/bar', name: 'Bar', language: haskell }}
    let(:guide3) {{ slug: 'pdep-utn/baz', name: 'Baz', language: haskell }}

    before { header 'Authorization', build_auth_header('*') }

    context 'when no guides in a course yet' do
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Classroom::Collection::Guides.for('foo').insert!(guide1.wrap_json) }
      before { Classroom::Collection::Guides.for('foo').insert!(guide2.wrap_json) }
      before { Classroom::Collection::Guides.for('bar').insert!(guide3.wrap_json) }
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [guide1, guide2] }
    end

  end

  describe 'get /courses/:course/students' do

    let(:student) {{ email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar' }}

    let(:student1) {{ student: student, course: { slug: 'example/foo' } }}
    let(:student2) {{ student: student, course: { slug: 'example/test' } }}

    before { header 'Authorization', build_auth_header('*') }

    context 'when guides already exists in a course' do
      before { Classroom::Collection::Students.for('foo').insert!(student1.wrap_json) }
      before { Classroom::Collection::Students.for('test').insert!(student2.wrap_json) }
      before { get '/courses/foo/students' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq students: [student1] }
    end

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

  describe 'get' do
    let(:progress1) {{
      guide: { slug: 'example/foo' },
      student: { name: 'jondoe', email: 'jondoe@gmail.com', social_id: 'github|123456' },
      exercise: { id: 177, name: 'foo' },
      submissions: [{ status: :passed }] }}

    let(:progress2) {{
      guide: { slug: 'example/foo' },
      student: { name: 'jondoe', email: 'jondoe@gmail.com', social_id: 'github|123456' },
      exercise: { id: 178, name: 'foo' },
      submissions: [{ status: :failed }, { status: :passed }] }}

    before { Classroom::Collection::ExerciseStudentProgress.for('k2048').insert!(progress1.wrap_json) }
    before { Classroom::Collection::ExerciseStudentProgress.for('k2048').insert!(progress2.wrap_json) }
    before { header 'Authorization', build_auth_header('*') }

    context 'get /courses/:course/guides/:organization/:repository/:student_id' do
      before { get '/courses/k2048/guides/example/foo/github%7c123456' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({ exercise_student_progress: [progress1, progress2] }.to_json) }
    end

    context '/courses/:course/guides/:organization/:repository/:student_id/:exercise_id' do
      before { get '/courses/k2048/guides/example/foo/github%7c123456/178' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq(progress2.to_json) }
    end
  end


  describe 'post /courses/:course/students' do
    let(:auth0) {double('auth0')}
    before { allow(Mumukit::Auth::User).to receive(:new).and_return(auth0) }
    before { allow(auth0).to receive(:update_permissions) }
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:student_json) { student.to_json }

    context 'when course exists' do
      before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo'}.wrap_json) }

      context 'when not authenticated' do
        before { post '/courses/foo/students', student_json }

        it { expect(last_response).to_not be_ok }
        it { expect(Classroom::Collection::Students.for('foo').count).to eq 0 }
      end

      context 'when authenticated' do
        before { header 'Authorization', build_auth_header('*') }
        before { post '/courses/foo/students', student_json }

        context 'and user does not exist' do
          let(:created_course_student) { Classroom::Collection::Students.for('foo').find_by({}).as_json }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_eq status: 'created' }
          it { expect(Classroom::Collection::Students.for('foo').count).to eq 1 }
          it { expect(created_course_student.deep_symbolize_keys).to eq(student.merge(social_id: 'github|user123456')) }
        end
        context 'and user already exists' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(last_response.status).to eq 400 }
          it { expect(last_response.body).to json_eq(message: 'Student already exist') }
        end
      end
    end

    context 'when course does not exist' do
      it 'rejects creating a student' do
        header 'Authorization', build_auth_header('*')

        post '/courses/foo/students', student_json

        expect(last_response).to_not be_ok
        expect(Classroom::Collection::Students.for('foo').count).to eq 0
      end
    end
  end

  describe 'post /courses/:course/comments' do
    let(:comment_json) {{exercise_id: 1, submission_id: 1, comment: {content: 'hola', type: 'good'}}.to_json}

    context 'when authenticated' do
      before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_comments) }
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/comments', comment_json }

      let(:comment) { Classroom::Collection::Comments.for('bar').find_by(submission_id: 1) }

      it { expect(comment.to_json).to eq(comment_json)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/comments', comment_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/bar'}.to_json) }
    end

  end

  describe 'get /courses/:course/comments/:exercise_id' do
    let(:comment1) { {exercise_id: 1, submission_id: 1, comment: {content: 'hola', type: 'bad'}} }
    let(:comment2) { {exercise_id: 1, submission_id: 2, comment: {content: 'hola', type: 'good'}} }
    let(:comment3) { {exercise_id: 2, submission_id: 3, comment: {content: 'hola', type: 'warning'}} }

    before do
      Classroom::Collection::Comments.for('baz').insert!(comment1.wrap_json)
      Classroom::Collection::Comments.for('baz').insert!(comment2.wrap_json)
      Classroom::Collection::Comments.for('baz').insert!(comment3.wrap_json)
    end

    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('example/baz') }
      before { get '/courses/baz/comments/1' }

      it { expect(last_response.body).to eq({comments: [comment1, comment2]}.to_json)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/baz') }
      before { get '/courses/baz/comments/1' }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/baz'}.to_json) }
    end

  end

  describe 'post /courses/:course/followers' do
    let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', social_id: 'social|1'}.to_json}

    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/followers', follower_json }

      it { expect(Classroom::Collection::Followers.for('bar').find_by(course: 'example/bar', email: 'aguspina87@gmail.com').to_json).to eq({course: 'example/bar', social_ids: ['social|1']}.to_json)}
    end

    context 'when repeat follower' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/followers', follower_json }
      before { post '/courses/bar/followers', follower_json }

      it { expect(Classroom::Collection::Followers.for('bar').find_by(course: 'example/bar', email: 'aguspina87@gmail.com').social_ids.count).to eq(1)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/followers', follower_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz. Permissions are foo/bar'}.to_json) }
    end

    context 'when not authenticated' do
      let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', social_id: 'social|1'}.to_json}
      before { post '/courses/baz/followers', follower_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Classroom::Collection::Followers.for('bar').count).to eq 0 }
    end

  end

  context 'delete /follower' do
    let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', social_id: 'social|1'}.to_json}
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/followers', follower_json }
    before { delete '/courses/bar/followers/aguspina87@gmail.com/social%7c1' }

    it { expect(Classroom::Collection::Followers.for('bar').find_by(course: 'example/bar', email: 'aguspina87@gmail.com').social_ids).to eq([]) }
  end

  context 'get /follower' do
    let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', social_id: 'social|1'}.to_json}
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/followers', follower_json }
    before { get '/courses/bar/followers/aguspina87@gmail.com' }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to eq({followers: [{course: 'example/bar', social_ids: ['social|1']}]}.to_json)}
  end

  describe 'post /courses/:course/permissions' do
    let(:auth0) {double('auth0')}
    let(:permissions_json) {{ email: 'aguspina87@gmail.com' }.to_json}
    before { allow(Mumukit::Auth::User).to receive(:from_email).and_return(auth0) }
    before { allow(auth0).to receive(:update_permissions) }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/permissions', permissions_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_eq status: 'created' }
  end

  describe 'get /courses/:course/exams' do
    let(:exam_json) { { slug: 'foo/bar', start_time: 'today', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo' } }
    let(:response_json) { JSON.parse(last_response.body).deep_symbolize_keys }

    before { header 'Authorization', build_auth_header('*') }
    before { Classroom::Collection::Exams.for('foo').insert! exam_json.wrap_json }
    before { get '/courses/foo/exams' }

    it { expect(last_response.body).to be_truthy }
    it { expect(response_json[:exams].first[:id]).to be_truthy }
    it { expect(response_json[:exams].first.except(:id).to_json).to eq(exam_json.to_json) }

  end

  describe 'post /courses/:course/exams' do
    let(:exam_json) { { slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', social_ids: [] }.stringify_keys }
    let(:result_json) { { slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', social_ids: [] }.stringify_keys }
    let(:exam_fetched) { Classroom::Collection::Exams.for('foo').where({}).as_json[:exams].first }

    before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_exams).with(exam_json.merge(tenant: 'example', id: kind_of(String))) }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_eq(status: 'created', id: kind_of(String)) }
    it { expect(Classroom::Collection::Exams.for('foo').count).to eq 1 }
    it { expect(exam_fetched['id']).to be_truthy }
    it { expect(exam_fetched.except('id')).to eq result_json }

  end

  describe 'get /courses/:course/exams/:exam_id' do
    let(:exam_json) {{ slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', social_ids: [] }}
    let(:exam_id) { Classroom::Collection::Exams.for('foo').insert!(exam_json.wrap_json)[:id] }
    let(:response_json) { JSON.parse(last_response.body).deep_symbolize_keys }

    before { header 'Authorization', build_auth_header('*') }
    before { get "/courses/foo/exams/#{exam_id}", exam_json.to_json }

    it { expect(response_json[:id]).to be_truthy }
    it { expect(response_json.except(:id)).to eq(exam_json) }
  end

  describe 'put /courses/:course/exams/:exam' do
    let!(:id) { Classroom::Collection::Exams.for('foo').insert! exam_json.wrap_json }
    let(:exam_json) { { slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', social_ids: ['auth0|234567', 'auth0|345678'] }.stringify_keys }
    let(:exam_json2) { exam_json.merge(social_ids: ['auth0|123456'], id: id[:id]).stringify_keys }
    let(:result_json) { { slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', social_ids: ['auth0|123456'] }.stringify_keys }
    let(:exam_fetched) { Classroom::Collection::Exams.for('foo').where({}).as_json[:exams].first }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_exams).exactly(1).times }
      before { header 'Authorization', build_auth_header('*') }
      before { put "/courses/foo/exams/#{id[:id]}", exam_json2.to_json }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_eq(status: 'updated', id: kind_of(String)) }
      it { expect(Classroom::Collection::Exams.for('foo').count).to eq 1 }
      it { expect(exam_fetched['id']).to eq(id[:id]) }
      it { expect(exam_fetched.except('id').to_json).to eq result_json.to_json }
    end

    context 'when no existing exam' do
      let(:exam_json2) { exam_json.merge(social_ids: ['auth0|123456'], id: '123').stringify_keys }
      before { header 'Authorization', build_auth_header('*') }
      it { expect { Classroom::Collection::Exams.for('foo').upsert! exam_json2 }.to raise_error(Classroom::ExamExistsError) }
    end

  end

end
