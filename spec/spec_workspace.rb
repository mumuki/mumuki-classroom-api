def initialize_workspaces(config)
  config.before(:each) do

    initialize_workspace :organization do
      haskell = create :language, name: 'haskell'
      gobstones = create :language, name: 'gobstones'
      create(:organization,
             name: 'example.org',
             book:
               create(:book,
                      slug: 'original/book',
                      chapters: [
                        create(:chapter,
                               slug: 'original/topic1',
                               name: 'Fundamentals',
                               lessons: [
                                 create(:lesson, slug: 'original/guide1', language: gobstones),
                                 create(:lesson, slug: 'original/guide2', language: gobstones)]),
                        create(:chapter,
                               slug: 'original/topic2',
                               name: 'Functional Programming',
                               lessons: [
                                 create(:lesson, slug: 'original/guide3', language: haskell),
                                 create(:lesson, slug: 'original/guide4', language: haskell)])])).tap &:switch!
    end

    initialize_workspace :courses do
      organization = Organization.current
      create :course, organization: organization, slug: 'example.org/foo'
      create :course, organization: organization, slug: 'example.org/foo2'
    end

    initialize_workspace :complements do
      create(:complement, slug: 'original/guide5', book: Organization.current.book, language: Language.for_name('gobstones'))
      create(:complement, slug: 'original/guide6', book: Organization.current.book, language: Language.for_name('haskell'))
    end

    initialize_workspace :exams do
      create(:exam,
             slug: 'original/guide7',
             organization: Organization.current,
             course: Course.locate!('example.org/foo'),
             language: Language.for_name('gobstones'))
    end
  end
end

def initialize_workspace(name)
  yield if RSpec.current_example.metadata[:workspaces]&.include? name
end
