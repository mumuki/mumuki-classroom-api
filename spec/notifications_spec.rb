require 'spec_helper'

describe 'notifications', organization_workspace: :test do

  let(:assignment) { Mumuki::Classroom::Assignment.create! organization: 'example.org', course: 'example.org/foo' }
  let(:notification) { {organization: 'example.org', course: 'example.org/foo', sender: 'foo@bar.com', assignment_id: assignment._id} }

  describe 'post /notifications/unread' do
    context 'when authenticated' do
      before { Mumuki::Classroom::Notification.create! notification }
      before { header 'Authorization', build_auth_header('example.org/*') }
      before { get '/notifications/unread' }

      it { expect(last_response.body).to json_like({notifications: [notification.merge(read: false)]},
                                                   {except: [:created_at, :updated_at, :assignment, :assignment_id, :id]}) }

    end

  end

end
