def initialize_workspaces(config)
  config.before(:each) do

    initialize_workspace :organization do
      create(:organization,
             name: 'example.org',
             book:
               create(:book,
                      slug: 'original/book',
                      chapters: [
                        create(:chapter,
                               slug: 'original/topic1',
                               lessons: [
                                 create(:lesson, slug: 'original/guide1'),
                                 create(:lesson, slug: 'original/guide2')]),
                        create(:chapter,
                               slug: 'original/topic2',
                               lessons: [
                                 create(:lesson, slug: 'original/guide3'),
                                 create(:lesson, slug: 'original/guide4')])])).tap &:switch!
    end

    initialize_workspace :courses do
      organization = Organization.current
      create :course, organization: organization, slug: 'example.org/foo'
      create :course, organization: organization, slug: 'example.org/foo2'
    end
  end
end

def initialize_workspace(name, parent_workspaces = [])
  parent_workspaces.each &method(:initialize_workspace)
  yield if RSpec.current_example.metadata[:workspaces]&.include? name
end
