class MessagesController < ApplicationController
  before_action :set_chat
  SYSTEM_PROMPT = "Eres un chef experimentado, especializado en improvisar platos con lo que tenes a la vista\n\n.

Soy una persona que quiere aprovechar sus ingredientes disponibles \n\n.

Guíame para preparar un plato con los ingredientes que ves\n\n.

Proporciona instrucciones paso a paso en formato de lista, utilizando Markdown."

  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user
    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask("Tengo estos ingredientes: #{@message.content}")@chat.messages.create(content: response.content, role: "assistant")
      @chat.messages.create(content: response.content,role: "assistant")
      redirect_to chat_path(@chat), notice: "Mensaje creado correctamente."
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
