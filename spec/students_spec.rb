require 'spec_helper'

describe Student do

  before do
    Classroom::Database.clean!
    Classroom::Collection::Users.upsert_permissions! 'github|123456', {}
  end

  let(:date) { Time.now }

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  let(:student1) { {uid: 'github|123456', first_name: 'Dorothy'} }
  let(:student2) { {uid: 'twitter|123456', first_name: 'John'} }

  let(:guide1) { {slug: 'foo/bar'} }
  let(:guide2) { {slug: 'bar/baz'} }

  let(:guide_student_progress1) { {guide: guide1, student: student1} }
  let(:guide_student_progress2) { {guide: guide2, student: student1} }
  let(:guide_student_progress3) { {guide: guide2, student: student2} }

  let(:exercise1) { {
    guide: guide1,
    student: student1,
    exercise: {id: 1},
    submissions: [
      {status: 'failed', created_at: date},
      {status: 'passed', created_at: date + 2.minutes},
      {status: 'failed', created_at: date + 1.minute}
    ]
  } }
  let(:exercise2) { {
    guide: guide1,
    student: student1,
    exercise: {id: 2},
    submissions: [
      {status: 'failed', created_at: date},
      {status: 'passed', created_at: date + 1.minute},
      {status: 'failed', created_at: date + 2.minutes}
    ]
  } }
  let(:exercise3) { {
    guide: guide2,
    student: student1,
    exercise: {id: 3},
    submissions: [
      {status: 'passed', created_at: date}
    ]
  } }
  let(:exercise4) { {
    guide: guide2,
    student: student2,
    exercise: {id: 4},
    submissions: [
      {status: 'failed', created_at: date},
      {status: 'passed_with_warnings', created_at: date + 2.minutes}
    ]
  } }
  let(:example_students) { -> (student) { Student.create!(student.merge(organization: 'example', course: 'example/example')) } }
  let(:students) { Student.where(organization: 'example', course: 'example/example') }
  let(:example_student_progresses) { -> (exercise) { Assignment.create! exercise.merge(organization: 'example', course: 'example/example') } }
  let(:example_guide_student_progresses) { -> (guide_progress) { GuideProgress.create! guide_progress.merge organization: 'example', course: 'example/example' } }

  describe do

    before { example_students.call student1 }
    before { example_students.call student2 }

    before { example_student_progresses.call exercise1 }
    before { example_student_progresses.call exercise2 }
    before { example_student_progresses.call exercise3 }
    before { example_student_progresses.call exercise4 }

    describe '#report' do
      let(:report) { Student.report({organization: 'example', course: 'example/example'}) }
      it { expect(report.count).to eq 2 }
      it { expect(report.first).to json_like({first_name: 'Dorothy'}, except_fields) }
      it { expect(report.second).to json_like({first_name: 'John'}, except_fields) }
    end

    context 'if no students stats processed' do
      it { expect(students.size).to eq 2 }
      it { expect(students.first.as_json).to json_like student1.merge(organization: 'example', course: 'example/example'), except_fields }
      it { expect(students.second.as_json).to json_like student2.merge(organization: 'example', course: 'example/example'), except_fields }
    end

    context 'if students stats processed' do
      before { Student.update_all_stats(organization: 'example', course: 'example/example') }

      it { expect(students.size).to eq 2 }
      it { expect(students.second.as_json).to json_like(student2.merge(stats: {passed: 0, passed_with_warnings: 1, failed: 0}, organization: 'example', course: 'example/example'), except_fields) }
      it { expect(students.first.as_json).to json_like(student1.merge(stats: {passed: 2, passed_with_warnings: 0, failed: 1}, organization: 'example', course: 'example/example'), except_fields) }
    end

    context 'delete student from students' do

      let(:guides) { Guide.where organization: 'example', course: 'example/example' }
      let(:students) { Student.where organization: 'example', course: 'example/example' }
      let(:guide_students_progress) { GuideProgress.where(organization: 'example', course: 'example/example').as_json }
      let(:exercise_student_progress) { example_student_progresses.all.as_json.deep_symbolize_keys[:exercise_student_progress] }

      before { Guide.create! guide1.merge(organization: 'example', course: 'example/example') }
      before { Guide.create! guide2.merge(organization: 'example', course: 'example/example') }

      before { example_guide_student_progresses.call guide_student_progress1 }
      before { example_guide_student_progresses.call guide_student_progress2 }
      before { example_guide_student_progresses.call guide_student_progress3 }

      before { Student.find_by!(uid: 'github|123456').destroy_cascade! }

      it { expect(guides.size).to eq 1 }
      it { expect(students.size).to eq 1 }
      it { expect(guide_students_progress.size).to eq 1 }
      it { expect(Assignment.count).to eq 1 }


    end

  end

  describe 'students routes' do

    describe 'get /courses/:course/students' do

      let(:student) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'example/bar'} }
      let(:student_saved) { {organization: 'example', course: 'example/foo'}.merge student }

      context 'when guides already exists in a course' do
        before { Student.create! student.merge(organization: 'example', course: 'example/foo') }
        before { Student.create! student.merge(organization: 'example', course: 'example/test') }

        context 'get students with auth0 client' do
          before { header 'Authorization', build_auth_header('*') }
          before { get '/courses/foo/students' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved]}, except_fields) }
        end
        context 'get students with auth client' do
          before { header 'Authorization', build_mumuki_auth_header('*') }
          before { get '/api/courses/foo/students' }

          it { expect(last_response).to be_ok }
          it { expect(last_response.body).to json_like({students: [student_saved]}, except_fields) }
        end
      end

    end
  end

  describe 'get /courses/:course/student/:uid' do
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:json) { {student: student.merge(uid: 'auth0|1'), course: {slug: 'example/foo'}} }
    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    before { Course.create! organization: 'example', name: 'foo', slug: 'example/foo' }
    before { Student.create!(student.merge(uid: 'auth0|1', organization: 'example', course: 'example/foo')) }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/student/auth0%7c1' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_like student.merge({organization: 'example', course: 'example/foo', uid: 'auth0|1'}), except_fields }
  end

  describe 'post /courses/:course/students/:student_id' do

    before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', uid: 'github|123456', tenant: 'example') }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/students/github%7C123456' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to eq({:status => :created}.to_json) }
  end

  describe 'when needs mumuki-user' do
    let(:fetched_student) { Student.find_by(uid: 'github|123456', organization: 'example', course: 'example/example') }


    describe 'post /courses/:course/students/:student_id/detach' do

      before { example_students.call student1 }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('example/*') }
        before { post '/courses/example/students/github%7C123456/detach', {}.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.detached).to eq true }
      end

    end

    describe 'post /courses/:course/students/:student_id/attach' do

      before { example_students.call student1.merge(detached: true, detached_at: Time.now) }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('example/*') }
        before { post '/courses/example/students/github%7C123456/attach', {}.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.detached).to eq nil }
        it { expect(fetched_student.detached_at).to eq nil }
      end

    end
    describe 'post /courses/:course/students' do
      let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo'} }
      let(:student_json) { student.to_json }

      context 'when course exists' do
        before { Course.create! organization: 'example', name: 'foo', slug: 'example/foo', uid: 'example/foo' }

        context 'when not authenticated' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(Student.count).to eq 0 }
        end

        context 'when authenticated' do
          before { header 'Authorization', build_auth_header('*') }

          context 'should publish in resubmissions queue' do
            before { expect(Mumukit::Nuntius).to receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user does not exist' do
              let(:created_course_student) { Student.find_by(organization: 'example', course: 'example/foo').as_json }
              let(:created_at) { 'created_at' }
              before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Student.where(organization: 'example', course: 'example/foo').count).to eq 1 }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example', course: 'example/foo'), except_fields) }
            end
          end
          context 'should not publish int resubmissions queue' do
            before { post '/courses/foo/students', student_json }
            before { expect(Mumukit::Nuntius).to_not receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user already exists by uid' do
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
            context 'and user already exists by email' do
              before { header 'Authorization', build_auth_header('*', 'auth1') }
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
          end
        end
      end

      context 'when course does not exist' do
        before { expect(Mumukit::Nuntius).to_not receive(:notify!) }

        it 'rejects creating a student' do
          header 'Authorization', build_auth_header('*')

          post '/courses/foo/students', student_json

          expect(last_response).to_not be_ok
          expect(Student.where(organization: 'example', course: 'example/foo').count).to eq 0
        end
      end
    end

    describe 'post /courses/:course/students' do
      let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', uid: 'jondoe@gmail.com', image_url: 'http://foo'} }
      let(:student_json) { student.to_json }

      context 'when course exists' do
        before { Course.create! organization: 'example', name: 'foo', slug: 'example/foo', uid: 'example/foo' }

        context 'when not authenticated' do
          before { post '/courses/foo/students', student_json }

          it { expect(last_response).to_not be_ok }
          it { expect(Student.where(organization: 'example', course: 'example/foo').count).to eq 0 }
        end

        context 'when authenticated' do
          before { header 'Authorization', build_auth_header('*') }

          context 'should publish int resubmissions queue' do
            before { expect(Mumukit::Nuntius).to receive(:notify!) }
            before { post '/courses/foo/students', student_json }
            context 'and user does not exist' do
              let(:created_course_student) { Student.find_by(organization: 'example', course: 'example/foo').as_json }
              let(:created_at) { 'created_at' }
              before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }

              it { expect(last_response).to be_ok }
              it { expect(last_response.body).to json_eq status: 'created' }
              it { expect(Student.where(organization: 'example', course: 'example/foo').count).to eq 1 }
              it { expect(created_course_student).to json_like(student.merge(uid: 'jondoe@gmail.com', organization: 'example', course: 'example/foo'), except_fields) }
            end
          end
          context 'should not publish int resubmissions queue' do
            before { post '/courses/foo/students', student_json }
            before { expect(Mumukit::Nuntius).to_not receive(:notify!) }
            context 'and user already exists by uid' do
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
            context 'and user already exists by email' do
              before { header 'Authorization', build_auth_header('*', 'auth1') }
              before { post '/courses/foo/students', student_json }

              it { expect(last_response).to_not be_ok }
              it { expect(last_response.status).to eq 400 }
              it { expect(last_response.body).to json_eq(message: 'Student already exist') }
            end
          end
        end
      end

      context 'when course does not exist' do
        before { expect(Mumukit::Nuntius).to_not receive(:notify!) }

        it 'rejects creating a student' do
          header 'Authorization', build_auth_header('*')

          post '/courses/foo/students', student_json

          expect(last_response).to_not be_ok
          expect(Student.where(organization: 'example', course: 'example/foo').count).to eq 0
        end
      end
    end
  end
end
