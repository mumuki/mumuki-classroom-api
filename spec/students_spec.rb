require 'spec_helper'

describe Classroom::Collection::Students do

  after do
    Classroom::Database.clean!
  end

  let(:created_at) { 'created_at' }
  let(:date) { Time.now }

  let(:student1) { {social_id: 'github|123456', first_name: 'John'} }
  let(:student2) { {social_id: 'github|234567', first_name: 'Dorothy'} }

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
  let(:example_students) { Classroom::Collection::Students.for('example') }
  let(:example_student_progresses) { Classroom::Collection::ExerciseStudentProgress.for('example') }
  let(:example_guide_student_progresses) { Classroom::Collection::GuideStudentsProgress.for('example') }

  describe do

    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    before { example_students.insert! student1.wrap_json }
    before { example_students.insert! student2.wrap_json }

    before { example_student_progresses.insert! exercise1.wrap_json }
    before { example_student_progresses.insert! exercise2.wrap_json }
    before { example_student_progresses.insert! exercise3.wrap_json }
    before { example_student_progresses.insert! exercise4.wrap_json }

    describe '#report' do
      let(:report) { example_students.report }
      it { expect(report.first).to json_like created_at: created_at, first_name: 'John' }
      it { expect(report.second).to json_like created_at: created_at, first_name: 'Dorothy' }
    end

    context 'if no students stats processed' do
      let(:students) { example_students.all.as_json.deep_symbolize_keys[:students] }

      it { expect(students.size).to eq 2 }
      it { expect(students.first).to eq student1.merge(created_at: created_at) }
      it { expect(students.second).to eq student2.merge(created_at: created_at) }
    end

    context 'if students stats processed' do
      let(:students) { example_students.all.as_json.deep_symbolize_keys[:students] }

      before { example_students.update_all_stats }

      it { expect(students.size).to eq 2 }
      it { expect(students.first).to eq student1.merge(created_at: created_at, stats: {passed: 2, passed_with_warnings: 0, failed: 1}) }
      it { expect(students.second).to eq student2.merge(created_at: created_at, stats: {passed: 0, passed_with_warnings: 1, failed: 0}) }
    end

    context 'delete student from students' do

      let(:guides) { Classroom::Collection::Guides.for('example').all.as_json.deep_symbolize_keys[:guides] }
      let(:students) { example_students.all.as_json.deep_symbolize_keys[:students] }
      let(:course_students) { Classroom::Collection::CourseStudents.all.raw }
      let(:guide_students_progress) { example_guide_student_progresses.all.as_json.deep_symbolize_keys[:guide_students_progress] }
      let(:exercise_student_progress) { example_student_progresses.all.as_json.deep_symbolize_keys[:exercise_student_progress] }

      before { Classroom::Collection::Guides.for('example').insert! guide1.wrap_json }
      before { Classroom::Collection::Guides.for('example').insert! guide2.wrap_json }

      before { Classroom::Collection::CourseStudents.insert!({student: student1, course: {slug: 'example/example'}}.wrap_json) }
      before { Classroom::Collection::CourseStudents.insert!({student: student2, course: {slug: 'example/example'}}.wrap_json) }
      before { Classroom::Collection::CourseStudents.insert!({student: student1, course: {slug: 'example/foo'}}.wrap_json) }

      before { example_guide_student_progresses.insert! guide_student_progress1.wrap_json }
      before { example_guide_student_progresses.insert! guide_student_progress2.wrap_json }
      before { example_guide_student_progresses.insert! guide_student_progress3.wrap_json }

      before { example_students.delete!('github|123456') }

      it { expect(course_students.size).to eq 2 }
      it { expect(course_students.first).to json_like student: {social_id: "github|234567",
                                                                first_name: 'Dorothy'},
                                                      course: {slug: "example/example"} }
      it { expect(course_students.second).to json_like student: {social_id: "github|123456",
                                                                 first_name: 'John'},
                                                       course: {slug: "example/foo"} }
      it { expect(guides.size).to eq 1 }
      it { expect(students.size).to eq 1 }
      it { expect(guide_students_progress.size).to eq 1 }
      it { expect(exercise_student_progress.size).to eq 1 }


    end

  end

  describe 'students routes' do

    describe 'get /courses/:course/students' do

      let(:created_at) { 'created_at' }
      before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
      let(:student) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar'} }

      let(:student1) { {student: student, course: {slug: 'example/foo'}, created_at: created_at} }
      let(:student2) { {student: student, course: {slug: 'example/test'}, created_at: created_at} }

      before { header 'Authorization', build_auth_header('*') }

      context 'when guides already exists in a course' do
        before { Classroom::Collection::Students.for('foo').insert!(student1.wrap_json) }
        before { Classroom::Collection::Students.for('test').insert!(student2.wrap_json) }
        before { get '/courses/foo/students' }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to json_eq students: [student1] }
      end

    end
  end

  describe 'get /courses/:course/student/:social_id' do
    let(:student) { {first_name: 'Jon', last_name: 'Doe', email: 'jondoe@gmail.com', image_url: 'http://foo'} }
    let(:json) { {student: student.merge(social_id: 'auth0|1'), course: {slug: 'example/foo'}} }
    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    before { Classroom::Collection::Courses.insert!({name: 'foo', slug: 'example/foo'}.wrap_json) }
    before { Classroom::Collection::CourseStudents.insert! json.wrap_json }
    before { Classroom::Collection::Students.for('foo').insert!(student.merge(social_id: 'auth0|1').wrap_json) }
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/student/auth0%7c1' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to json_eq student.merge(created_at: created_at, social_id: 'auth0|1') }
  end

  describe 'post /courses/:course/students/:student_id' do

    before { expect(Mumukit::Nuntius::Publisher).to receive(:publish_resubmissions).with(social_id: 'github|123456', tenant: 'example') }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/students/github%7C123456' }

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to eq({:status => :created}.to_json) }
  end

  describe 'when needs mumuki-user' do
    let(:auth0) { double('auth0') }
    let(:fetched_student) { example_students.find_by(social_id: 'github|123456') }

    before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish) }
    before { allow(Mumukit::Auth::Store).to receive(:get).and_return(auth0) }
    before { allow(auth0).to receive(:protect!) }

    describe 'post /courses/:course/students/:student_id/detach' do

      before { allow(auth0).to receive(:remove_permission!) }
      before { example_students.insert! student1.wrap_json }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('example/*') }
        before { post '/courses/example/students/github%7C123456/detach', {}.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.detached).to eq true }
      end

    end

    describe 'post /courses/:course/students/:student_id/attach' do

      before { allow(auth0).to receive(:add_permission!) }
      before { example_students.insert! student1.merge(detached: true, detached_at: Time.now).wrap_json }

      context 'should transfer student to destination and transfer all his data' do
        before { header 'Authorization', build_auth_header('example/*') }
        before { post '/courses/example/students/github%7C123456/attach', {}.to_json }

        it { expect(last_response).to be_ok }
        it { expect(last_response.body).to eq({:status => :updated}.to_json) }
        it { expect(fetched_student.detached).to eq nil }
        it { expect(fetched_student.detached_at).to eq nil }
      end

    end
  end
end
