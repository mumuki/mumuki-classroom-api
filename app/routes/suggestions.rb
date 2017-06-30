helpers do
  def exercise_id
    params[:exercise_id].to_i
  end
end

Mumukit::Platform.map_organization_routes!(self) do
  get '/suggestions/:organization/:repository/:exercise_id' do
    authorize! :teacher
    Suggestion.where(guide_slug: repo_slug, 'exercise.eid': exercise_id)
  end
end
