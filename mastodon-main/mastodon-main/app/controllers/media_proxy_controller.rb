# frozen_string_literal: true

class MediaProxyController < ApplicationController
  include RoutingHelper
  include Authorization
  include Redisable
  include Lockable

  skip_before_action :require_functional!

  before_action :authenticate_user!, if: :whitelist_mode?

  rescue_from ActiveRecord::RecordInvalid, with: :not_found
  rescue_from Mastodon::UnexpectedResponseError, with: :not_found
  rescue_from Mastodon::NotPermittedError, with: :not_found
  rescue_from HTTP::TimeoutError, HTTP::ConnectionError, OpenSSL::SSL::SSLError, with: :internal_server_error

  def show
    with_redis_lock("media_download:#{params[:id]}") do
      @media_attachment = MediaAttachment.remote.attached.find(params[:id])
      authorize @media_attachment.status, :show?
      redownload! if @media_attachment.needs_redownload? && !reject_media?
    end

    redirect_options = { allow_other_host: true }

    if should_disable_gradients?
      redirect_options[:params] = { gradients: false }
    end

    redirect_to full_asset_url(@media_attachment.file.url(version)), redirect_options
  end

  private

  def redownload!
    @media_attachment.download_file!
    @media_attachment.created_at = Time.now.utc
    @media_attachment.save!
  end

  def version
    if request.path.end_with?('/small')
      :small
    else
      :original
    end
  end

  def reject_media?
    DomainBlock.reject_media?(@media_attachment.account.domain)
  end

  def should_disable_gradients?
    !current_user&.settings&.show_colorful_gradients
  end
end


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
