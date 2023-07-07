require 'rails_helper'

RSpec.describe MediaProxyController, type: :controller do
  let(:media_attachment) { create(:media_attachment) }
  let(:user) { create(:user) }

  describe 'GET #show' do
    context 'when media needs redownload and gradients are disabled' do
      before do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:whitelist_mode?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
        allow(media_attachment).to receive(:needs_redownload?).and_return(true)
        allow(controller).to receive(:reject_media?).and_return(false)
        allow(user.settings).to receive(:show_colorful_gradients).and_return(false)
        get :show, params: { id: media_attachment.id }
      end

      it 'redownloads the media attachment' do
        expect(media_attachment).to have_received(:download_file!)
      end

      it 'saves the media attachment' do
        expect(media_attachment).to have_received(:save!)
      end

      it 'redirects to the media attachment file URL without gradients' do
        expect(response).to redirect_to("#{media_attachment.file.url(:original)}?gradients=false")
      end
    end

    context 'when media does not need redownload or gradients are enabled' do
      before do
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:whitelist_mode?).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
        allow(media_attachment).to receive(:needs_redownload?).and_return(false)
        allow(controller).to receive(:reject_media?).and_return(false)
        allow(user.settings).to receive(:show_colorful_gradients).and_return(true)
        get :show, params: { id: media_attachment.id }
      end

      it 'does not redownload the media attachment' do
        expect(media_attachment).not_to have_received(:download_file!)
      end

      it 'does not save the media attachment' do
        expect(media_attachment).not_to have_received(:save!)
      end

      it 'redirects to the media attachment file URL with default options' do
        expect(response).to redirect_to(media_attachment.file.url(:original))
      end
    end
  end
end
