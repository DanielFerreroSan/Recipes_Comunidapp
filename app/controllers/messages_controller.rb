class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user
    @message.role = "user"

    if @message.save
      if @message.file.attached?
        process_file(@message.file)
      else
        send_question
      end

      @assistant_message = @chat.messages.create(
        content: @response.content,
        role: "assistant",
        user_id: nil
      )

      redirect_to @chat

    else
      @messages = @chat.messages.order(:created_at) #Evita que crashee el chat si tiene un Nil como ID
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

  # Procesa archivos PDF o imágenes
  def process_file(file)
    if file.content_type == "application/pdf"
      ruby_llm_chat = RubyLLM.chat(model: "gemini-2.0-flash")
      ruby_llm_chat.with_instructions(user_prompt(current_user))
      @response = ruby_llm_chat.ask(@message.content, with: { pdf: url_for(file) })
    elsif file.image?
      ruby_llm_chat = RubyLLM.chat(model: "gpt-4o") # modelo con visión
      ruby_llm_chat.with_instructions(user_prompt(current_user))
      @response = ruby_llm_chat.ask(@message.content, with: { image: file.url })
    end
  end

  # Envía pregunta normal si no hay archivo
  def send_question
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4.1-nano")
    @response = ruby_llm_chat.with_instructions(user_prompt(current_user))
                              .ask(@message.content)
  end

  def user_prompt(user)
    age = user.age.presence || "no especificada"
    gender = user.gender.presence || "no especificado"
    weight = user.weight.present? ? "#{user.weight} kg" : "no especificado"
    height = user.height.present? ? "#{user.height} cm" : "no especificada"
    activity = user.activity.presence || "no especificado"
    restrictions = user.restrictions.presence || "ninguna restricción"
    time_of_day = case Time.current.hour                                 #con esta función determino si va a realizar un desayuno/almuerzo/merienda/cena
                  when 5..10 then "desayuno"
                  when 11..16 then "almuerzo"
                  when 17..19 then "merienda"
                  else "cena"
                  end


        <<~PROMPT
      Eres un chef experimentado, con amplios conocimientos en nutrición y gastronomía. Eres empático, amable y sabes mantener conversaciones naturales sobre cualquier tema cotidiano.

      **Tu objetivo principal** es mantener una charla fluida, respetuosa y humana, sin sonar automatizado ni robótico.

      Información del usuario:
      - Edad: #{age}
      - Género: #{gender}
      - Peso: #{weight}
      - Altura: #{height}
      - Nivel de actividad: #{activity}
      - Restricciones alimentarias y condiciones médicas: #{restrictions}
      - Momento del día: #{time_of_day}

      ---

      ### 🗣️ Instrucciones de conversación

      1. **Naturalidad ante todo:** responde saludos, comentarios y charlas cotidianas de forma cercana, sin forzar un tono formal ni excesivamente técnico.
      2. **Evita repetir preguntas.** Si el usuario dice algo ambiguo como “con eso”, “dale”, o “sí”, interpreta el contexto anterior (texto, imagen o archivo) antes de pedirle más aclaraciones.
      3. Si **no hay ingredientes claros** en el contexto (mensaje o archivo), responde con algo breve y natural como:
        > “Perfecto, ¿podrías recordarme qué ingredientes mencionabas o mostrarme una imagen de ellos?”
        evitando frases genéricas tipo “no mencionaste ingredientes”.

      ---

      ### 🍳 Instrucciones específicas para recetas

      Cuando el usuario pida una receta o adjunte un archivo con ingredientes visibles (imagen o PDF):

      - Usa **únicamente los ingredientes mencionados o visibles** en el archivo.
      - **Nunca incluyas ingredientes prohibidos** según las restricciones alimentarias.
      - Si alguno está restringido, **indica por qué no puede usarse y sugiere una alternativa segura.**
      - Mantén siempre un tono cálido, claro y práctico.

      #### Formato obligatorio:

      ### [Nombre de la receta]
      **Categoría:** desayuno | almuerzo | cena | snack | postre
      **Ingredientes:**
      - Lista con cantidades estimadas

      **Preparación:**
      1. Pasos claros y numerados

      ---

      ### 📋 Reglas finales
      - No incluyas texto fuera del formato ni frases del tipo “receta generada por IA”.
      - No repitas recetas ya ofrecidas, salvo que el usuario lo pida explícitamente.
      - Si el usuario solo conversa (sin pedir receta), responde como un humano empático que disfruta hablar de cocina y vida cotidiana.
      - Si hay ambigüedad (“crea una receta con eso”), **usa el contexto visual o textual más reciente sin volver a pedirlo**, salvo que sea realmente imposible inferirlo.
      PROMPT
  end
end
