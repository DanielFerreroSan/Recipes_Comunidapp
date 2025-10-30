class ChatsController < ApplicationController

def index
    @chats = Chat.all
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(created_at: :asc) # mostrar los mensajes del chat
    @message = @chat.messages.build                  # preparar un nuevo mensaje
  end

  def create
    @chat = current_user.chats.build(chat_params)
    if @chat.save
      redirect_to @chat, notice: "Chat creado exitosamente."
    else
      render :new, alert: "Error al crear el chat."
    end
  end

end
