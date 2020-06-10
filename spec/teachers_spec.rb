require 'spec_helper'

describe Mumuki::Classroom::Teacher do

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  let(:response) { struct JSON.parse(last_response.body) }

  describe 'get /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', uid: 'auth0|1'} }
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Mumuki::Classroom::Teacher.create! teacher.merge(organization: 'example.org', course: 'example.org/foo') }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({teachers: [teacher.merge(organization: 'example.org', course: 'example.org/foo')]}, except_fields) }
    end

  end

  describe 'post /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar'} }

    context 'when success' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to be_ok }
      it { expect(Mumuki::Classroom::Teacher.count).to eq 1 }
      it { expect(Mumuki::Classroom::Teacher.first.as_json).to json_like(teacher.merge(organization: 'example.org', course: 'example.org/foo', uid: 'foobar@gmail.com'), except_fields) }
    end

    context 'when no permissions' do
      before { header 'Authorization', build_auth_header('') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Mumuki::Classroom::Teacher.count).to eq 0 }
    end

  end

  describe 'post api/courses/massive/:course/teachers' do
    let(:organization) { create :organization, name: 'example.org' }
    let(:teachers) do
      (1..120).map do |it|
        {first_name: "first_name_#{it}", last_name: "last_name_#{it}", email: "email_#{it}@fake.com"}
      end
    end
    let(:teachers_uids) { teachers.map { |it| it[:email] } }
    let(:teachers_json) { {teachers: teachers}.to_json }
    let(:query) { {organization: organization, course: 'example.org/foo'} }

    context 'when course exists' do
      let!(:existing_course) { create(:course, {organization: organization, slug: 'example.org/foo'}) }

      context 'when authenticated' do
        before { header 'Authorization', build_auth_header('*') }

        context 'and users do not exist' do

          before { post '/api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 20 }
          it { expect(response.processed_count).to eq 100 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(Mumuki::Classroom::Teacher.where(query).in(uid: teachers_uids).count).to eq 100 }
        end

        context 'and some users do exist' do
          before do
            teachers_uids.take(50).each do |it|
              user = User.create(uid: it)
              user.add_permission! :teacher, 'example.org/foo2'
              user.save!
              Mumuki::Classroom::Teacher.create!(organization: 'example.org', course: 'example.org/foo2', uid: it)
            end
          end

          before { post '/api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 20 }
          it { expect(response.processed_count).to eq 100 }
          it { expect(response.errored_members_count).to eq nil }
          it { expect(response.errored_members_reason).to eq nil }
          it { expect(Mumuki::Classroom::Teacher.where(query).in(uid: teachers_uids).count).to eq 100 }
          it { expect(User.where(uid: teachers_uids).count).to eq 100 }
          it { expect(User.where(uid: teachers_uids).select { |it| it.teacher_of? struct(slug: 'example.org/foo') }.count).to eq 100 }
          it { expect(User.where(uid: teachers_uids).select { |it| it.teacher_of? struct(slug: 'example.org/foo2') }.count).to eq 50 }
        end

        context 'and some teachers do exist' do
          before do
            teachers_uids.take(50).each do |it|
              user = User.create(uid: it)
              user.add_permission! :teacher, 'example.org/foo'
              user.save!
              Mumuki::Classroom::Teacher.create!(organization: 'example.org', course: 'example.org/foo', uid: it)
            end
          end

          before { post 'api/courses/foo/massive/teachers', teachers_json }

          it { expect(last_response).to be_ok }
          it { expect(response.status).to eq 'created' }
          it { expect(response.unprocessed_count).to eq 20 }
          it { expect(response.processed_count).to eq 50 }
          it { expect(response.errored_members_count).to eq 50 }
          it { expect(response.errored_members_reason).to eq 'Teachers already belong to current course' }
          it { expect(Mumuki::Classroom::Teacher.where(query).in(uid: teachers_uids).count).to eq 100 }
        end
      end

    end

  end
end
