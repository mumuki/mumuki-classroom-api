require 'spec_helper'

describe 'notifications' do

  let(:assignment) {Assignment.create! organization: 'example', course: 'example/foo'}
  let(:notification) {{organization: 'example', course: 'example/foo', sender: 'foo@bar.com', assignment_id: assignment._id}}

  describe 'post /notifications/unread' do
    context 'when authenticated' do
      before {Notification.create! notification}
      before {header 'Authorization', build_auth_header('example/*')}
      before {get '/notifications/unread'}

      it {expect(last_response.body).to json_like([notification.merge(read: false)],
                                                  except: [:created_at, :updated_at, :assignment, :assignment_id, :id])}

    end

  end

end
