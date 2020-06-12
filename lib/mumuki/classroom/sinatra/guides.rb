class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    get '/guides/:organization/:repository' do
      authorize! :teacher
      guide = Guide.locate!(repo_slug)
      validate_usage! guide
      {guide: with_language(guide)}
    end

    get '/courses/:course/guides' do
      authorize! :teacher
      ensure_organization_exists!
      ensure_course_exists!
      {guides: with_language(current_organization.guides)}
    end

    get '/api/courses/:course/guides' do
      authorize! :teacher
      ensure_organization_exists!
      ensure_course_exists!
      {guides: with_language(current_organization.guides)}
    end
  end

  helpers do
    def with_language(joinable)
      joinable.as_json(except: [:id, :created_at, :updated_at],
                       includes: {
                         language: {
                           only: [:name, :devicon, :comment_type]}})
    end

    def validate_usage!(guide)
      raise ActiveRecord::RecordNotFound, "Couldn't find #{Guide.name} with #{Guide.sync_key_id_field}: #{guide.slug}" unless guide.usage_in_organization
    end
  end
end
