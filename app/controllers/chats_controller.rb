class ChatsController < ApplicationController

  def index
   @chats = Chat.order(created_at: :desc).limit(8)
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(created_at: :asc) # mostrar los mensajes del chat
    @message = @chat.messages.build                  # preparar un nuevo mensaje
  end

  def create
    puts params
    @chat = Chat.new
    @chat.title = "nuevo"
    @chat.user = current_user

    # @chat = current_user.chats.build(chat_params)
    puts "Paso 2"
    if @chat.save
      redirect_to @chat, notice: "Chat creado exitosamente."
    else
      redirect_to chats_path, alert: "Error al crear el chat."
    end
  end

  def destroy
    @chat = Chat.find(params[:id])
    @chat.destroy
    redirect_to chats_path, notice: "Chat eliminado correctamente."
  end

  private

  def chat_params
    params.permit(:title)
  end

end
