require 'rspec'
require_relative 'statuses_helper'

RSpec.describe StatusesHelper, type: :helper do
  describe '#status_description' do
    it 'returns the correct status description' do
      status = double('Status', text: 'This is a status', spoiler_text: '', ordered_media_attachments: [])
      
      description = helper.status_description(status)
      
      expect(description).to eq('This is a status')
    end

    it 'returns the correct status description with media and poll' do
      status = double('Status', text: 'This is a status', spoiler_text: '', ordered_media_attachments: [double('MediaAttachment')], preloadable_poll: double('Poll', options: ['Option 1', 'Option 2']))

      description = helper.status_description(status)

      expect(description).to eq("This is a status\n\n[ ] Option 1\n[ ] Option 2")
    end

    it 'returns the correct status description with spoiler text' do
      status = double('Status', text: 'This is a status', spoiler_text: 'Spoiler warning', ordered_media_attachments: [])

      description = helper.status_description(status)

      expect(description).to eq('Spoiler warning')
    end
  end

  describe '#stream_link_target' do
    it 'returns _blank when in embedded view' do
      allow(helper).to receive(:embedded_view?).and_return(true)

      link_target = helper.stream_link_target

      expect(link_target).to eq('_blank')
    end

    it 'returns nil when not in embedded view' do
      allow(helper).to receive(:embedded_view?).and_return(false)

      link_target = helper.stream_link_target

      expect(link_target).to be_nil
    end
  end
end


# Especificar el archivo de prueba y requerir las dependencias necesarias
require 'rspec'
require_relative 'status'

# Describir el comportamiento del modelo que contiene la asociación
RSpec.describe Status, type: :model do
  describe 'associations' do
    it 'belongs to a thread' do
      association = described_class.reflect_on_association(:thread)
      
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:foreign_key]).to eq('in_reply_to_id')
      expect(association.options[:class_name]).to eq('Status')
      expect(association.options[:inverse_of]).to eq(:replies)
      expect(association.options[:optional]).to be_truthy
      expect(association.options[:touch]).to be_truthy
    end
  end
end




describe "#set_status" do
  before do
    @account = FactoryBot.create(:account)
    @status = FactoryBot.create(:status, account: @account)
  end

  it "assigns @status correctly if it exists" do
    get :set_status, params: { id: @status.id }
    expect(assigns(:status)).to eq(@status)
  end

  it "raises ActiveRecord::RecordNotFound if the post does not exist" do
    expect {
      get :set_status, params: { id: 123 }
    }.to raise_error(ActiveRecord::RecordNotFound, "The post does not exist")
  end

  it "authorizes @status with :show?" do
    expect(controller).to receive(:authorize).with(@status, :show?)
    get :set_status, params: { id: @status.id }
  end

  it "calls not_found if Mastodon::NotPermittedError is raised" do
    expect(controller).to receive(:not_found)
    allow(controller).to receive(:authorize).and_raise(Mastodon::NotPermittedError)
    get :set_status, params: { id: @status.id }
  end
end



describe "#redirect_to_original" do
  before do
    @status = FactoryBot.create(:status)
    @reblog = FactoryBot.create(:status)
    @status.reblog = @reblog
    @tag_manager = ActivityPub::TagManager.instance
  end

  it "redirects to the original post if @status is a reblog" do
    allow(@tag_manager).to receive(:url_for).and_return("http://example.com/original_post")

    expect {
      get :redirect_to_original, params: { id: @status.id }
    }.to redirect_to("http://example.com/original_post")
  end

  it "raises ActiveRecord::RecordNotFound if the original post does not exist" do
    @status.reblog = nil

    expect {
      get :redirect_to_original, params: { id: @status.id }
    }.to raise_error(ActiveRecord::RecordNotFound, "The original post does not exist")
  end
end


