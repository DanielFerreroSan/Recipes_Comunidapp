class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user
    @message.role = "user"

    if @message.save
      build_conversation_history

      if @message.file.attached?
        process_file(@message.file)
      else
        send_question
      end

      @assistant_message = @chat.messages.create(
        content: @response.content,
        role: "assistant"
      )

      respond_to do |format|
        # 🚀 Si la petición viene de fetch (AJAX)
        format.js { render partial: "messages/message", locals: { message: @assistant_message }, formats: [:html] }

        # 🚪 Si viene por navegación normal
        format.html { redirect_to @chat }
      end

    else
      @messages = @chat.messages.order(:created_at)
      render "chats/show", status: :unprocessable_entity
    end
  end


  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content, :file)
  end

  def build_conversation_history    # GENERA HISTORIAL
    @ruby_llm_chat = RubyLLM.chat
    @chat.messages.order(:created_at).each do |message|
      @ruby_llm_chat.add_message(
        role: message.role,
        content: message.content
      )
    end
  end


    def process_file(file)
    model =
      case file.content_type
      when "application/pdf" then "gemini-2.0-flash"
      when /^image\// then "gpt-4o"
      when /^audio\// then "gpt-4o-audio-preview"
      else "gpt-4.1-nano"
      end

    ruby_llm_chat = @ruby_llm_chat.with_model(model)

    Dir.mktmpdir do |dir|
      require "open-uri"
      temp_file_path = File.join(dir, file.filename.to_s)

      URI.open(url_for(file)) do |remote_file|
        File.binwrite(temp_file_path, remote_file.read)
      end

      case file.content_type
      when "application/pdf"
        @response = ruby_llm_chat.ask(@message.content, with: { pdf: temp_file_path })
      when /^image\//
        @response = ruby_llm_chat.ask(@message.content, with: { image: temp_file_path })
      when /^audio\//
        @response = ruby_llm_chat.ask(@message.content, with: { audio: temp_file_path })
      end
    end
  end

  def send_question               #  PREGUNTA NORMAL
    ruby_llm_chat = @ruby_llm_chat.with_model("gpt-4.1-nano")
    system_instructions = user_prompt(current_user)
    ruby_llm_chat.add_message(role: "system", content: system_instructions)
    @response = ruby_llm_chat.ask(@message.content)
  end

  def user_prompt(user)
  age = user.age.presence || "no especificada"
  gender = user.gender.presence || "no especificado"
  weight = user.weight.present? ? "#{user.weight} kg" : "no especificado"
  height = user.height.present? ? "#{user.height} cm" : "no especificada"
  activity = user.activity.presence || "no especificado"
  restrictions = user.restrictions.presence || "ninguna restricción"
  time_of_day = case Time.current.hour
                when 5..10 then "desayuno"
                when 11..16 then "almuerzo"
                when 17..19 then "merienda"
                else "cena"
                end

    <<~PROMPT
      Eres un chef experimentado, con amplios conocimientos en nutrición y gastronomía. Eres empático, amable y mantienes conversaciones naturales sobre cualquier tema cotidiano.

      **Tu objetivo principal** es mantener una charla fluida, respetuosa y humana, sin sonar automatizado ni robótico.

      Información del usuario:
      - Edad: #{age}
      - Género: #{gender}
      - Peso: #{weight}
      - Altura: #{height}
      - Nivel de actividad: #{activity}
      - Restricciones alimentarias y condiciones médicas: #{restrictions}
      - Momento del día: #{time_of_day}

      - Instrucciones específicas para recetas

          - Cuando el usuario pida una receta, o adjunte un archivo o imagen con ingredientes visibles, usa **únicamente esos ingredientes**.
          - Si los ingredientes no son claros, menciona solo los que se distingan con certeza.
          - **Siempre devuelve la receta en el formato exacto siguiente, incluso si proviene de una imagen:**

          ###**[NombreDeLaReceta]**
          **Categoría:** desayuno | almuerzo | cena | snack | postre
          **Ingredientes:**
          - Cantidad + ingrediente
          - Cantidad + ingrediente

          **Preparación:**
          1. Paso 1
          2. Paso 2

          - No agregues texto antes ni después del bloque de receta.
          - No incluyas introducciones como “podemos preparar”, “aquí tienes la receta”, “buen provecho”, etc.
          - Usa Markdown solo para listas y encabezados como en el ejemplo.
          - Mantén siempre un tono cálido, claro y práctico.

      - Instrucciones para audios

          - Interpreta los audios como texto.
          - No menciones que es un audio; responde como si fuera texto normal.
          - Mantén las mismas reglas de recetas y tono empático.

      - Instrucciones de conversación

          1. **Naturalidad ante todo:** responde saludos, comentarios y charlas cotidianas de forma cercana.
          2. **Evita repetir preguntas.** Si el usuario dice algo ambiguo como “con eso”, “dale”, o “sí”, interpreta el contexto anterior antes de pedir aclaraciones.

      - Reglas finales

          - No incluyas texto fuera del formato ni frases del tipo “receta generada por IA”.
          - Si el usuario solo conversa, responde como un humano empático que disfruta hablar de cocina.
          - Para ambigüedades como “crea una receta con eso”, usa el contexto más reciente sin volver a pedirlo.
          - **Siempre devuelve solo una receta por mensaje.**

    PROMPT

  end

end
