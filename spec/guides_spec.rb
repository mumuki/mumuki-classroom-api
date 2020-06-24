require 'spec_helper'

describe Guide, workspaces: [:organization, :courses, :complements, :exams] do

  let(:response) { JSON.parse last_response.body, object_class: OpenStruct }

  describe 'GET http://localmumuki.io/:organization/courses/:course/guides' do
    before { header 'Authorization', build_auth_header('*') }

    context 'retrive chapters from current organization book' do
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(response.chapters.count).to eq 2 }
      it { expect(response.chapters.first.name).to eq 'Fundamentals' }
      it { expect(response.chapters.second.name).to eq 'Functional Programming' }
      it { expect(response.chapters.first.number).to eq 1 }
      it { expect(response.chapters.second.number).to eq 2 }
      it { expect(response.chapters.first.lessons.count).to eq 2 }
      it { expect(response.chapters.second.lessons.count).to eq 2 }
      it { expect(response.chapters.first.lessons.first.number).to eq 1 }
      it { expect(response.chapters.first.lessons.first.guide.slug).to eq 'original/guide1' }
      it { expect(response.chapters.first.lessons.first.guide.students_count).to eq 0 }
      it { expect(response.chapters.first.lessons.first.guide.language.name).to eq 'gobstones' }
      it { expect(response.chapters.first.lessons.second.number).to eq 2 }
      it { expect(response.chapters.first.lessons.second.guide.slug).to eq 'original/guide2' }
      it { expect(response.chapters.first.lessons.second.guide.language.name).to eq 'gobstones' }
      it { expect(response.chapters.second.lessons.first.number).to eq 1 }
      it { expect(response.chapters.second.lessons.first.guide.slug).to eq 'original/guide3' }
      it { expect(response.chapters.second.lessons.first.guide.language.name).to eq 'haskell' }
      it { expect(response.chapters.second.lessons.second.number).to eq 2 }
      it { expect(response.chapters.second.lessons.second.guide.slug).to eq 'original/guide4' }
      it { expect(response.chapters.second.lessons.second.guide.language.name).to eq 'haskell' }
    end

    context 'retrive complements from current organization book' do
      before { get '/courses/foo/guides' }

      it { expect(response.complements.count).to eq 2 }
      it { expect(response.complements.first.guide.slug).to eq 'original/guide5' }
      it { expect(response.complements.first.guide.language.name).to eq 'gobstones' }
      it { expect(response.complements.second.guide.slug).to eq 'original/guide6' }
      it { expect(response.complements.second.guide.language.name).to eq 'haskell' }
    end

    context 'retrive exams from current organization and course' do
      context 'when course has exams' do
        before { get '/courses/foo/guides' }

        it { expect(response.exams.count).to eq 1 }
        it { expect(response.exams.first.guide.slug).to eq 'original/guide7' }
        it { expect(response.exams.first.guide.language.name).to eq 'gobstones' }
      end
      context 'when course has not got exams' do
        before { get '/courses/foo2/guides' }

        it { expect(response.exams.count).to eq 0 }
      end
    end
  end

  describe 'GET http://localmumuki.io/:organization/api/courses/:course/guides' do
    before { header 'Authorization', build_auth_header('*') }

    context 'retrive chapters from current organization book' do
      before { Mumuki::Classroom::GuideProgress.create! guide: {slug: 'original/guide1'}, course: 'example.org/foo', organization: 'example.org' }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(response.chapters.count).to eq 2 }
      it { expect(response.chapters.first.name).to eq 'Fundamentals' }
      it { expect(response.chapters.second.name).to eq 'Functional Programming' }
      it { expect(response.chapters.first.number).to eq 1 }
      it { expect(response.chapters.second.number).to eq 2 }
      it { expect(response.chapters.first.lessons.count).to eq 2 }
      it { expect(response.chapters.second.lessons.count).to eq 2 }
      it { expect(response.chapters.first.lessons.first.number).to eq 1 }
      it { expect(response.chapters.first.lessons.first.guide.slug).to eq 'original/guide1' }
      it { expect(response.chapters.first.lessons.first.guide.students_count).to eq 1 }
      it { expect(response.chapters.first.lessons.first.guide.language.name).to eq 'gobstones' }
      it { expect(response.chapters.first.lessons.second.number).to eq 2 }
      it { expect(response.chapters.first.lessons.second.guide.slug).to eq 'original/guide2' }
      it { expect(response.chapters.first.lessons.second.guide.language.name).to eq 'gobstones' }
      it { expect(response.chapters.second.lessons.first.number).to eq 1 }
      it { expect(response.chapters.second.lessons.first.guide.slug).to eq 'original/guide3' }
      it { expect(response.chapters.second.lessons.first.guide.language.name).to eq 'haskell' }
      it { expect(response.chapters.second.lessons.second.number).to eq 2 }
      it { expect(response.chapters.second.lessons.second.guide.slug).to eq 'original/guide4' }
      it { expect(response.chapters.second.lessons.second.guide.language.name).to eq 'haskell' }
    end

    context 'retrive complements from current organization book' do
      before { get '/api/courses/foo/guides' }

      it { expect(response.complements.count).to eq 2 }
      it { expect(response.complements.first.guide.slug).to eq 'original/guide5' }
      it { expect(response.complements.first.guide.language.name).to eq 'gobstones' }
      it { expect(response.complements.second.guide.slug).to eq 'original/guide6' }
      it { expect(response.complements.second.guide.language.name).to eq 'haskell' }
    end

    context 'retrive exams from current organization and course' do
      context 'when course has exams' do
        before { get '/api/courses/foo/guides' }

        it { expect(response.exams.count).to eq 1 }
        it { expect(response.exams.first.guide.slug).to eq 'original/guide7' }
        it { expect(response.exams.first.guide.language.name).to eq 'gobstones' }
      end
      context 'when course has not got exams' do
        before { get '/api/courses/foo2/guides' }

        it { expect(response.exams.count).to eq 0 }
      end
    end
  end

  describe 'GET http://localmumuki.io/guides/:organization/:repository' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when guide has usage in current organization' do
      before { get '/guides/original/guide1' }

      it { expect(last_response).to be_ok }
      it { expect(response.guide.slug).to eq 'original/guide1' }
      it { expect(response.guide.language.name).to eq 'gobstones' }
    end

    context 'when guide has not got usage in current organization' do
      before { create :guide, slug: 'foo/bar' }
      before { get '/guides/foo/bar' }

      it { expect(last_response).to_not be_ok }
      it { expect(response.message).to eq "Couldn't find Guide with slug: foo/bar" }
    end
  end
end
