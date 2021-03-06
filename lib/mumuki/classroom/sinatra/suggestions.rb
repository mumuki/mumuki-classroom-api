class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def exercise_id
      params[:exercise_id].to_i
    end
  end

  Mumukit::Platform.map_organization_routes!(self) do
    get '/suggestions/:organization/:repository/:exercise_id' do
      authorize! :teacher
      { suggestions: Mumuki::Classroom::Suggestion
        .where(guide_slug: repo_slug, 'exercise.eid': exercise_id)
        .sort(updated_at: :desc)
        .map { |s| s.as_json(methods: :content_html).merge(id: s.id) } }
    end
  end
end
