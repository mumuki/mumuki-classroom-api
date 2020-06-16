class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    get '/guides/:organization/:repository' do
      authorize! :teacher
      guide = Guide.locate!(repo_slug)
      validate_usage! guide
      {guide: guide_needed_fields(guide)}
    end

    get '/courses/:course/guides' do
      get_current_guides
    end

    get '/api/courses/:course/guides' do
      get_current_guides
    end
  end

  helpers do
    def get_current_guides
      authorize! :teacher
      ensure_organization_exists!
      ensure_course_exists!
      {
        chapters: chapter_needed_fields(current_organization.book.chapters),
        complements: guide_container_needed_fields(current_organization.book.complements),
        exams: guide_container_needed_fields(current_organization.exams.where(course: current_course))
      }
    end

    def except_fields
      [:id, :created_at, :updated_at, :language_id, :guide_id, :topic_id, :book_id]
    end

    def guide_container_as_json_opts
      {except: except_fields, include: {guide: guide_as_json_opts}}
    end

    def guide_as_json_opts
      {except: except_fields, include: {language: {only: [:name, :devicon]}}}
    end

    def guide_needed_fields(guide)
      guide.as_json guide_as_json_opts
    end

    def guide_container_needed_fields(container)
      container.as_json guide_container_as_json_opts
    end

    def chapter_needed_fields(chapter)
      chapter.as_json(except: except_fields, include: {lessons: guide_container_as_json_opts}, methods: :name)
    end

    def validate_usage!(guide)
      raise ActiveRecord::RecordNotFound, "Couldn't find #{Guide.name} with #{Guide.sync_key_id_field}: #{guide.slug}" unless guide.usage_in_organization
    end
  end
end
