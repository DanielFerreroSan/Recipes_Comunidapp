class MessagesController < ApplicationController
  before_action :set_chat
  def create
    @message = @chat.messages.build(message_params) #.build es el equivalente a hacer @message = Message.new(message_params) + @message.chat = @chat
    if @message.save
      respond_to do |format|
        format.html {redirect_to chat_path(@chat)}
        format.turbo_srtream
      end
    else
      respond_to do |format|
        format.html {render "chats/show", status: :unprocessable_entity}
        format.turbo_srtream {render turbo_stream: turbo_stream.replace"message_form", partial: "messages/form", locals: { chat: @chat, message: @message }) }
      end
    end
  end

  private
  def set_chat"message_form", partial: "messages/form", locals: { chat: @chat, message: @message })
    @chat = Chat.find(params[:chat_id])
  end
  def message_params
    params.require(:message).permit(:content)
  end
end
