require 'spec_helper'

describe 'Massive API', workspaces: [:organization, :courses] do

  def to_member_request_hash(number)
    {first_name: "first_name_#{number}", last_name: "last_name_#{number}", email: "email_#{number}@fake.com"}
  end

  def to_guide_progress(guide, uid, stats, eid, status)
    {
      organization: organization.name,
      course: course.slug,
      guide: {slug: guide.slug},
      student: {uid: uid, first_name: uid, last_name: uid, email: uid},
      stats: {passed: stats.first, passed_with_warnings: stats.second, failed: stats.third},
      last_assignment: {exercise: {eid: eid}, submission: {status: status}}
    }
  end

  def to_assignment(guide, uid, status, eid)
    {
      guide: {slug: guide.slug},
      student: {uid: uid, first_name: uid, last_name: uid, email: uid},
      submissions: [{status: status}],
      exercise: {eid: eid}
    }
  end

  def create_students_in(course, uids, student = {})
    uids.each do |it|
      User.new(uid: it).tap { |u| u.add_permission! :student, course.slug }.save!
      Mumuki::Classroom::Student.create!({
        organization: course.organization.name,
        course: course.slug,
        uid: it,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.email
      }.merge(student))
    end
  end

  def create_teachers_in(course, uids)
    uids.each do |it|
      User.new(uid: it).tap { |u| u.add_permission! :teacher, course.slug }.save!
      Mumuki::Classroom::Teacher.create!(
        {organization: course.organization.name, course: course.slug, uid: it}
      )
    end
  end

  def students_from(course, uids)
    Mumuki::Classroom::Student.where(organization: course.organization.name, course: course.slug).in(uid: uids)
  end

  def teachers_from(course, uids)
    Mumuki::Classroom::Teacher.where(organization: course.organization.name, course: course.slug).in(uid: uids)
  end

  def students_users_count_from(course, uids)
    User.where(uid: uids).select { |it| it.student_of? course }.count
  end

  def teachers_users_count_from(course, uids)
    User.where(uid: uids).select { |it| it.teacher_of? course }.count
  end

  Mumuki::Classroom::App::MASSIVE_BATCH_LIMIT = 10

  let(:response) { struct JSON.parse(last_response.body) }

  let(:organization) { Organization.locate! 'example.org' }
  let(:course) { Course.locate! 'example.org/foo' }
  let(:course2) { Course.locate! 'example.org/foo2' }

  let(:students) { (1..12).map { |it| to_member_request_hash it } }
  let(:students_uids) { students.map { |it| it[:email] } }
  let(:students_json) { {students: students}.to_json }

  let(:teachers) { (1..12).map { |it| to_member_request_hash it } }
  let(:teachers_uids) { teachers.map { |it| it[:email] } }
  let(:teachers_json) { {teachers: teachers}.to_json }

  let(:uids) { {uids: students_uids} }
  let(:uids_json) { uids.to_json }

  let(:language) { Language.for_name 'haskell' }

  let(:guide) { create :guide, slug: 'foo/bar', name: 'bar', language: language }
  let(:guide2) { create :guide, slug: 'foo/baz', name: 'baz', language: language }

  let(:jane) { create :user, uid: 'jane.doe@testing.com' }
  let(:john) { create :user, uid: 'john.doe@testing.com' }

  let(:guide_progress1) { to_guide_progress guide, jane.uid, [2, 2, 0], 2, :passed }
  let(:guide_progress2) { to_guide_progress guide, john.uid, [2, 0, 1], 1, :passed_with_warnings }
  let(:guide_progress3) { to_guide_progress guide2, jane.uid, [0, 1, 0], 1, :passed_with_warnings }

  let(:assignment1) { to_assignment guide, jane.uid, :passed, 1 }
  let(:assignment2) { to_assignment guide, jane.uid, :failed, 2 }
  let(:assignment3) { to_assignment guide, jane.uid, :passed, 3 }

  let(:empty_exercises) { {exercises: []}.to_json }
  let(:exercises_data) { {
    exercises: [
      {id: 1, tag_list: %w(ex1_a ex1_b)},
      {id: 2, tag_list: %w(ex2_a ex2_b), language: 'e2_lang'},
      {id: 3, tag_list: %w(ex3_a ex3_b), language: 'e3_lang'}
    ],
    language: 'guide_language'
  }.to_json }

  let(:exam_json) { {
    organization: organization.name,
    course: course.slug,
    slug: guide.slug,
    language: guide.language.name,
    name: guide.name,
    start_time: start_time,
    end_time: end_time,
    duration: 150,
    max_problem_submissions: 5,
    max_choice_submissions: 1,
    results_hidden_for_choices: false,
    passing_criterion_type: 'none'
  } }

  let(:start_time) { 1.month.ago.beginning_of_day }
  let(:end_time) { 1.month.since.beginning_of_day }

  shared_examples 'with verified names for users' do
    it { expect(modified_users.all? { |us| us.verified_first_name == us.first_name }).to be true }
    it { expect(modified_users.all? { |us| us.verified_last_name == us.last_name }).to be true }
  end

  describe 'when authenticated' do
    before { header 'Authorization', build_auth_header('*') }

    context 'Teachers API' do

      context 'POST http://localmumuki.io/:organization/api/courses/:course/massive/teachers' do
        let(:modified_users) { User.where(uid: students_uids) }

        context 'when teachers and users does not exist' do
          before { post '/api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(teachers_from(course, teachers_uids).count).to eq 10 }
          it { expect(teachers_users_count_from course, teachers_uids).to eq 10 }
          it { expect(teachers_users_count_from course2, teachers_uids).to eq 0 }
          it { expect(teachers_from(course, teachers_uids).first.created_at).to be_an ActiveSupport::TimeWithZone }
          it { expect(teachers_from(course, teachers_uids).first.updated_at).to be_an ActiveSupport::TimeWithZone }
          it_behaves_like 'with verified names for users'
        end

        context 'when none teachers exists in course but some of them already exist as users' do
          before { create_teachers_in course2, teachers_uids.take(5) }
          before { post '/api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(teachers_from(course, teachers_uids).count).to eq 10 }
          it { expect(teachers_users_count_from course, teachers_uids).to eq 10 }
          it { expect(teachers_users_count_from course2, teachers_uids).to eq 5 }
          it { expect(teachers_from(course, teachers_uids).first.created_at).to be_an ActiveSupport::TimeWithZone }
          it { expect(teachers_from(course, teachers_uids).first.updated_at).to be_an ActiveSupport::TimeWithZone }
          it_behaves_like 'with verified names for users'
        end

        context 'when some teachers exists in course and some of them already exist as users' do
          let(:modified_users) { User.where(uid: students_uids.take(5)) }
          before { create_teachers_in course, teachers_uids.take(5) }
          before { post 'api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 5 }
          it { expect(response.errored_members_count).to eq 5 }
          it { expect(teachers_from(course, teachers_uids).count).to eq 10 }
          it { expect(teachers_users_count_from course, teachers_uids).to eq 10 }
          it { expect(teachers_users_count_from course2, teachers_uids).to eq 0 }
          it { expect(teachers_from(course, teachers_uids).first.created_at).to be_an ActiveSupport::TimeWithZone }
          it { expect(teachers_from(course, teachers_uids).first.updated_at).to be_an ActiveSupport::TimeWithZone }
          it_behaves_like 'with verified names for users'
        end
      end
    end

    context 'Students API' do

      context 'GET http://localmumuki.io/:organization/api/courses/:course/massive/students' do

        def to_massive_result(progress)
          {
            student: progress[:student][:uid],
            guide: progress[:guide][:slug],
            progress: progress.except(:guide, :student)
          }
        end

        let(:ef) { {except: [:created_at, :updated_at, 'created_at', 'updated_at']} }

        before { Mumuki::Classroom::GuideProgress.create! guide_progress1 }
        before { Mumuki::Classroom::GuideProgress.create! guide_progress2 }
        before { Mumuki::Classroom::GuideProgress.create! guide_progress3 }
        before { Mumuki::Classroom::Assignment.create! assignment1 }
        before { Mumuki::Classroom::Assignment.create! assignment2 }
        before { Mumuki::Classroom::Assignment.create! assignment3 }

        context 'when guide_progress exist' do
          before { get '/api/courses/foo/massive/students' }

          it { expect(last_response).to be_ok }
          it { expect(response.page).to eq 1 }
          it { expect(response.total_pages).to eq 1 }
          it { expect(response.total_results).to eq 3 }
          it { expect(response.total_page_results).to eq 3 }
          it { expect(response.guide_students_progress.first).to json_like to_massive_result(guide_progress1), ef }
          it { expect(response.guide_students_progress.second).to json_like to_massive_result(guide_progress3), ef }
          it { expect(response.guide_students_progress.third).to json_like to_massive_result(guide_progress2), ef }
        end

      end

      context 'POST http://localmumuki.io/:organization/api/courses/:course/massive/students' do
        let(:modified_users) { User.where(uid: students_uids) }

        context 'when students and users does not exist' do
          before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', hash_including(:uid, :tenant)).exactly(10).times }
          before { post '/api/courses/foo/massive/students', students_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(students_from(course, students_uids).count).to eq 10 }
          it { expect(students_users_count_from course, students_uids).to eq 10 }
          it { expect(students_users_count_from course2, students_uids).to eq 0 }
          it { expect(students_from(course, students_uids).first.created_at).to be_an ActiveSupport::TimeWithZone }
          it { expect(students_from(course, students_uids).first.updated_at).to be_an ActiveSupport::TimeWithZone }
          it_behaves_like 'with verified names for users'
        end

        context 'when students and users does not exist' do
          let(:students) { [1,1,2,2,3,3,4,4,5,5,6,6].map { |it| to_member_request_hash it } }

          before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', hash_including(:uid, :tenant)).exactly(5).times }
          before { post '/api/courses/foo/massive/students', students_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
        end

        context "when students don't exist in course but some of them already exist as users" do
          before { create_students_in course2, students_uids.take(5) }
          before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', hash_including(:uid, :tenant)).exactly(10).times }
          before { post '/api/courses/foo/massive/students', students_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(students_from(course, students_uids).count).to eq 10 }
          it { expect(students_users_count_from course, students_uids).to eq 10 }
          it { expect(students_users_count_from course2, students_uids).to eq 5 }
          it { expect(students_from(course, students_uids).first.created_at).to be_an ActiveSupport::TimeWithZone }
          it { expect(students_from(course, students_uids).first.updated_at).to be_an ActiveSupport::TimeWithZone }
          it_behaves_like 'with verified names for users'
        end

        context 'when some students exist in course and some of them already exist as users' do
          let(:modified_users) { User.where(uid: students_uids.take(5)) }
          before { create_students_in course, students_uids.take(5) }
          before { expect(Mumukit::Nuntius).to receive(:notify!).with('resubmissions', hash_including(:uid, :tenant)).exactly(5).times }
          before { post 'api/courses/foo/massive/students', students_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 5 }
          it { expect(response.errored_members_count).to eq 5 }
          it { expect(students_from(course, students_uids).count).to eq 10 }
          it { expect(students_users_count_from course, students_uids).to eq 10 }
          it { expect(students_users_count_from course2, students_uids).to eq 0 }
          it { expect(students_from(course, students_uids).first.created_at).to be_an ActiveSupport::TimeWithZone }
          it { expect(students_from(course, students_uids).first.updated_at).to be_an ActiveSupport::TimeWithZone }
          it_behaves_like 'with verified names for users'
        end
      end

      context 'POST http://localmumuki.io/:organization/api/courses/:course/massive/students/attach' do

        context 'when all students belong to course and all of them are detached' do
          before { create_students_in course, students_uids, detached: true, detached_at: Time.now }
          before { post 'api/courses/foo/massive/students/attach', uids_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(students_from(course, students_uids).exists(detached: false).count).to eq 10 }
          it { expect(students_users_count_from course, students_uids).to eq 12 }
        end

        context 'when all students belong to course and some of them are detached' do
          before { create_students_in course, students_uids.take(6), detached: true, detached_at: Time.now }
          before { create_students_in course, students_uids.drop(6).take(4) }
          before { create_students_in course, students_uids.drop(10) }
          before { post 'api/courses/foo/massive/students/attach', uids_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(students_from(course, students_uids).count).to eq 12 }
          it { expect(students_from(course, students_uids).exists(detached: false).count).to eq 12 }
          it { expect(students_users_count_from course, students_uids).to eq 12 }
        end

        context 'when some students belong to course and some of them are detached' do
          before { create_students_in course, students_uids.take(3), detached: true, detached_at: Time.now }
          before { create_students_in course, students_uids.drop(3).take(4) }
          before { post 'api/courses/foo/massive/students/attach', uids_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 7 }
          it { expect(response.errored_members_count).to eq 3 }
          it { expect(students_from(course, students_uids).count).to eq 7 }
          it { expect(students_from(course, students_uids).exists(detached: false).count).to eq 7 }
          it { expect(students_users_count_from course, students_uids).to eq 7 }
        end
      end

      context 'POST http://localmumuki.io/:organization/api/courses/:course/massive/students/detach' do

        context 'when all students belong to course and all of them are attached' do
          before { create_students_in course, students_uids }
          before { post 'api/courses/foo/massive/students/detach', uids_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(students_from(course, students_uids).count).to eq 12 }
          it { expect(students_from(course, students_uids).exists(detached: true, detached_at: true).count).to eq 10 }
          it { expect(students_users_count_from course, students_uids).to eq 2 }
        end

        context 'when all students belong to course and some of them are attached' do
          before { create_students_in course, students_uids.take(6) }
          before { create_students_in course, students_uids.drop(6).take(4), detached: true, detached_at: Time.now }
          before { create_students_in course, students_uids.drop(10) }

          before { post 'api/courses/foo/massive/students/detach', uids_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(students_from(course, students_uids).count).to eq 12 }
          it { expect(students_from(course, students_uids).exists(detached: true, detached_at: true).count).to eq 10 }
          it { expect(students_users_count_from course, students_uids).to eq 2 }
        end

        context 'when some students belong to course and some of them are attached' do
          before { create_students_in course, students_uids.take(3) }
          before { create_students_in course, students_uids.drop(3).take(4), detached: true, detached_at: Time.now }
          before { post 'api/courses/foo/massive/students/detach', {uids: students_uids.take(10)}.to_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.unprocessed_count).to eq nil }
          it { expect(response.unprocessed_reason).to eq nil }
          it { expect(response.unprocessed).to eq nil }
          it { expect(response.processed_count).to eq 7 }
          it { expect(response.errored_members_count).to eq 3 }
          it { expect(students_from(course, students_uids).count).to eq 7 }
          it { expect(students_from(course, students_uids).exists(detached: true, detached_at: true).count).to eq 7 }
          it { expect(students_users_count_from course, students_uids).to eq 0 }
        end
      end
    end

    describe 'Exams API' do

      let(:classroom_id) { Exam.import_from_resource_h!(exam_json).classroom_id }
      let(:exam_uids) { {uids: range.map { |it| "user_uid_#{it}@testing.com" }} }
      let(:exam_fetched) { Exam.last }
      let(:uids) { exam_uids[:uids] }

      describe 'POST http://localmumuki.io/:organization/api/courses/:course/massive/exams/:exam/students' do

        before { uids.map { |it| create :user, uid: it } }
        before { Exam.upsert_students! eid: classroom_id, added: [jane.uid, john.uid] }
        before do
          uids.take(students_count).each do |it|
            Mumuki::Classroom::Student.create! uid: it,
                                               first_name: Faker::Name.first_name,
                                               last_name: Faker::Name.last_name,
                                               email: Faker::Internet.email,
                                               organization: organization.name,
                                               course: course.slug
          end
        end
        before { post "/api/courses/foo/massive/exams/#{classroom_id}/students", exam_uids.to_json }

        context 'when request exceeds batch limit and some students does not belong to course' do
          let(:range) { (1..12) }
          let(:students_count) { 3 }

          it { expect(Exam.count).to eq 1 }
          it { expect(exam_fetched.users.size).to eq 5 }
          it { expect(last_response.body).to be_truthy }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.processed).to match_array uids.take(3) }
          it { expect(response.processed_count).to eq 3 }
          it { expect(response.unprocessed).to match_array uids.drop(10) }
          it { expect(response.unprocessed_count).to eq 2 }
          it { expect(response.unprocessed_reason).to eq 'This endpoint process only first 10 elements' }
          it { expect(response.errored_members).to match_array uids.drop(3).take(7) }
          it { expect(response.errored_members_count).to eq 7 }
          it { expect(response.errored_members_reason).to eq 'Students does not belong to current course' }
        end

        context 'when request not exceeds batch limit and some students does not belong to course' do
          let(:range) { (1..10) }
          let(:students_count) { 3 }

          it { expect(Exam.count).to eq 1 }
          it { expect(exam_fetched.users.size).to eq 5 }
          it { expect(last_response.body).to be_truthy }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.processed).to match_array uids.take(3) }
          it { expect(response.processed_count).to eq 3 }
          it { expect(response.unprocessed).to be_nil }
          it { expect(response.unprocessed_count).to be_nil }
          it { expect(response.unprocessed_reason).to be_nil }
          it { expect(response.errored_members).to match_array uids.drop(3).take(7) }
          it { expect(response.errored_members_count).to eq 7 }
          it { expect(response.errored_members_reason).to eq 'Students does not belong to current course' }
        end

        context 'when request not exceeds batch limit and all students belong to course' do
          let(:range) { (1..10) }
          let(:students_count) { 10 }

          it { expect(Exam.count).to eq 1 }
          it { expect(exam_fetched.users.size).to eq 12 }
          it { expect(last_response.body).to be_truthy }
          it { expect(response.status).to eq 'updated' }
          it { expect(response.processed).to match_array uids }
          it { expect(response.processed_count).to eq 10 }
          it { expect(response.unprocessed).to be_nil }
          it { expect(response.unprocessed_count).to be_nil }
          it { expect(response.unprocessed_reason).to be_nil }
          it { expect(response.errored_members).to be_nil }
          it { expect(response.errored_members_count).to be_nil }
          it { expect(response.errored_members_reason).to be_nil }
        end
      end
    end
  end
end
