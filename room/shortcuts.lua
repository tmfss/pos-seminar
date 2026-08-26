return {

  ['PresentationCover'] = function(args, kwargs)
    local title = pandoc.utils.stringify(kwargs["title"] or "Presentation Title")
    local where = pandoc.utils.stringify(kwargs["where"] or "Local/Event")
    local author = pandoc.utils.stringify(kwargs["author"] or "Presentation Author")
    local logos_raw = pandoc.utils.stringify(kwargs["logo"] or "")
    local back_img = pandoc.utils.stringify(kwargs["back_img"] or "https://www.popsci.com/wp-content/uploads/2024/04/03/chaotic-galaxy.jpg?quality=85")

    -- 1. Construir o HTML das imagens dinamicamente
    local logos_html = ""
    if logos_raw ~= "" then
      -- Quebra a string por vírgulas e itera sobre cada link
      for logo_path in string.gmatch(logos_raw, '([^,]+)') do
        -- Remove espaços em branco do início e do fim (trim)
        logo_path = logo_path:match("^%s*(.-)%s*$")
        
        if logo_path ~= "" then
          logos_html = logos_html .. string.format('  <img src="%s" alt="logo">\n', logo_path)
        end
      end
    end

    -- 2. Template principal atualizado (agora com apenas 4 %s)
    local template = [[
<section data-background-image="%s">
<div class="boxing">
<div class="linha-gradiente"> </div>
<div class="subtitulo"> %s </div> 
<h1 class="titulo-principal"> %s </h1> 
<p style="color: #8c9baf; font-size: 1.2em;"> %s </p> 
<div style="display: flex; justify-content: flex-end;">
<div class="caixa-logos">
%s</div>
</div>
</div>
</section>
]]
    
    local final_html = string.format(template, back_img,  where, title , author , logos_html )
    return pandoc.RawBlock('html', final_html)
  end,

  ['ChapterCover'] = function(args, kwargs)
    local numbering = pandoc.utils.stringify(kwargs["numbering"] or "")
    local title = pandoc.utils.stringify(kwargs["title"] or "Título")
    local desc = pandoc.utils.stringify(kwargs["desc"] or "")
    local img = pandoc.utils.stringify(kwargs["img"] or "")
    
    local template = [[
::::: {.capitulo-grid}
:::: {.capitulo-textos}
<div class="NumberingGradient" style="margin-bottom: 10px;"> %s</div>
<div style="display: flex; align-items: flex-end; margin-bottom: 30px;">
  <h1 class="titulo-principal"> %s </h1>
</div>
<div class="desc"> %s </div>
::::

:::: {.capitulo-imagem}
![](%s)
::::
:::::
]]
    
    local markdown_final = string.format(template, numbering, title, desc, img)
    return pandoc.read(markdown_final).blocks
  end, 

  ['MakeIndex'] = function(args, kwargs)
    local html_cards = ""
    local num_sections = 0

    -- O loop pula de 2 em 2 (Título e Descrição)
    for i = 1, #args, 2 do
      num_sections = num_sections + 1
      
      -- Pega o título e a descrição (se a descrição não for passada, fica vazia)
      local title = pandoc.utils.stringify(args[i])
      local desc = ""
      if i + 1 <= #args then
        desc = pandoc.utils.stringify(args[i+1])
      end

      -- Formata o número com dois dígitos (01, 02, 03...)
      local num_str = string.format("%02d", num_sections)

      -- Template de cada card individual
      local card_template = [[
<div class="fragment indice-card" data-fragment-index="%d">
<div class="numero"> %s </div>
<div class="textos">
<strong> %s </strong>
<div class="desc">
%s
</div>
</div>
</div>
]]
      
      -- Injeta as variáveis no card e adiciona ao HTML final
      -- As variáveis são: fragment-index, numero formatado, título, descrição
      html_cards = html_cards .. string.format(card_template, num_sections, num_str, title, desc)
    end

    -- Envolve todos os cards na div grid principal
    local final_html = string.format('<div class="indice-grid">\n%s\n</div>', html_cards)
    
    return pandoc.RawBlock('html', final_html)
  end,

  ['MakeChapter'] = function(args, kwargs)
    local numbering = pandoc.utils.stringify(kwargs["numbering"] or "")
    local titulo = pandoc.utils.stringify(kwargs["titulo"] or "Título")
    local desc = pandoc.utils.stringify(kwargs["desc"] or "")
    local img = pandoc.utils.stringify(kwargs["img"] or "")
    
    -- Corrigi um errinho onde havia ":::: {.capitulo-textos}" repetido
    local template = [[
::::: {.capitulo-grid}
:::: {.capitulo-textos}
<div class="NumberingGradient" style="margin-bottom: 10px;"> %s</div>
<div style="display: flex; align-items: flex-end; margin-bottom: 30px;">
  <h1 class="titulo-principal"> %s </h1>
</div>
<div class="desc"> %s </div>
::::

:::: {.capitulo-imagem}
![](%s)
::::
:::::
]]
    
    local markdown_final = string.format(template, numbering, titulo, desc, img)
    return pandoc.read(markdown_final).blocks
  end, 
  -- ^^ ATENÇÃO À VÍRGULA AQUI! É ela que separa uma função da outra!

  -- ==========================================
  -- 2. SHORTCODE: InsertVideo
  -- ==========================================
  ['InsertVideo'] = function(args, kwargs)

    local type = pandoc.utils.stringify(kwargs["type"] or "")
    local desc = pandoc.utils.stringify(kwargs["desc"] or "")
    local PATH = pandoc.utils.stringify(kwargs["PATH"] or "")
    local is_fragment = pandoc.utils.stringify(kwargs["fragment"] or "false")
    
    -- Se fragment="true", adicionamos a classe do Reveal.js!
    local frag_class = ""
    if is_fragment == "true" then
      frag_class = "fragment"
    end

    desc = desc:gsub("%$(.-)%$", "\\(%1\\)")
    type = type:gsub("%$(.-)%$", "\\(%1\\)") -- Faz o mesmo pro título, por garantia
    -- Usei %% para escapar a porcentagem! E coloquei "%s" no src.
    local template = [[
<div class="%s" style="display: flex; flex-direction: column; justify-content: center; align-items: center; height: 50vh; width: 100%%;">
  <p4 style="font-size: 1.4rem; color: #adb5bd; margin-top: 15px; text-align: center;">
    <strong>%s </strong> %s
  </p4>
  <video data-autoplay muted loop playsinline controls width="60%%">
    <source src="%s" type="video/webm">
  </video>
</div>
]]
    
    local html_final = string.format(template, frag_class, type, desc, PATH)
    
    -- Como é HTML puro, usamos RawBlock. Isso garante ZERO erros com o Reveal.js!
    return pandoc.RawBlock('html', html_final)
  end,
    ['VideoVideo'] = function(args, kwargs)
    local desc1 = pandoc.utils.stringify(kwargs["desc1"] or "")
    local src1 = pandoc.utils.stringify(kwargs["src1"] or "")
    local desc2 = pandoc.utils.stringify(kwargs["desc2"] or "")
    local src2 = pandoc.utils.stringify(kwargs["src2"] or "")
    local is_fragment = pandoc.utils.stringify(kwargs["fragment"] or "false")
    
    -- Se fragment="true", adicionamos a classe do Reveal.js!
    local frag_class = ""
    if is_fragment == "true" then
      frag_class = "fragment"
    end

    desc1 = desc1:gsub("%$(.-)%$", "\\(%1\\)")
    desc2 = desc2:gsub("%$(.-)%$", "\\(%1\\)")
    local template = [[
<div class="%s" style="display: flex; flex-direction: row; justify-content: space-between; align-items: center; width: 100%%; height: 50vh;">
  
  <div style="width: 48%%; text-align: center;">
    <video autoplay muted loop playsinline width="100%%">
      <source src="%s" type="video/webm">
    </video>
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
  </div>

  <div style="width: 48%%; text-align: center;">
    <video autoplay muted loop playsinline width="100%%">
      <source src="%s" type="video/webm">
    </video>
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
  </div>

</div>
]]

    local html_final = string.format(template, frag_class, src1, desc1, src2, desc2)
    return pandoc.RawBlock('html', html_final)
  end,
    ['VideoImage'] = function(args, kwargs)
    local desc1 = pandoc.utils.stringify(kwargs["desc1"] or "")
    local src1 = pandoc.utils.stringify(kwargs["src1"] or "")
    local desc2 = pandoc.utils.stringify(kwargs["desc2"] or "")
    local src2 = pandoc.utils.stringify(kwargs["src2"] or "")
    local is_fragment = pandoc.utils.stringify(kwargs["fragment"] or "false")
    
    -- Se fragment="true", adicionamos a classe do Reveal.js!
    local frag_class = ""
    if is_fragment == "true" then
      frag_class = "fragment"
    end

    desc1 = desc1:gsub("%$(.-)%$", "\\(%1\\)")
    desc2 = desc2:gsub("%$(.-)%$", "\\(%1\\)")
    local template = [[
<div class="%s" style="display: flex; flex-direction: row; justify-content: space-between; align-items: center; width: 100%%; height: 50vh;">
  
  <div style="width: 40%%; text-align: center;">
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
    <video autoplay muted loop playsinline width="100%%">
      <source src="%s" type="video/webm">
    </video>
  </div>

  <div style="width: 58%%; text-align: center; height: 50vh;">
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
    <img src="%s" width="100%%" alt="_">
  </div>

</div>
]]

    local html_final = string.format(template, frag_class, desc1, src1, desc2, src2)
    return pandoc.RawBlock('html', html_final)
  end,

  ['InsertColumn3'] = function(args, kwargs)
    local desc1 = pandoc.utils.stringify(kwargs["desc1"] or "")
    local src1 = pandoc.utils.stringify(kwargs["src1"] or "")
    local desc2 = pandoc.utils.stringify(kwargs["desc2"] or "")
    local src2 = pandoc.utils.stringify(kwargs["src2"] or "")
    local desc3 = pandoc.utils.stringify(kwargs["desc3"] or "")
    local src3 = pandoc.utils.stringify(kwargs["src3"] or "")
    local is_fragment = pandoc.utils.stringify(kwargs["fragment"] or "false")
    
    -- Se fragment="true", adicionamos a classe do Reveal.js!
    local frag_class = ""
    if is_fragment == "true" then
      frag_class = "fragment"
    end

    desc1 = desc1:gsub("%$(.-)%$", "\\(%1\\)")
    desc2 = desc2:gsub("%$(.-)%$", "\\(%1\\)")
    desc3 = desc3:gsub("%$(.-)%$", "\\(%1\\)")
    local template = [[
<div class="%s" style="display: flex; flex-direction: row; justify-content: space-between; align-items: center; width: 100%%; height: 50vh;">
  
  <div style="width: 32%%; text-align: center;">
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
    <video autoplay muted loop playsinline width="100%%">
      <source src="%s" type="video/webm">
    </video>
  </div>

  <div style="width: 32%%; text-align: center;">
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
    <video autoplay muted loop playsinline width="100%%">
      <source src="%s" type="video/webm">
    </video>
  </div>

  <div style="width: 32%%; text-align: center;">
    <h4 style="font-size: 1.2rem; color: #dee2e6; margin-bottom: 15px;"> %s </h4>
    <video autoplay muted loop playsinline width="100%%">
      <source src="%s" type="video/webm">
    </video>
  </div>

</div>
]]

    local html_final = string.format(template, frag_class, desc1, src1, desc2, src2, desc3, src3)
    return pandoc.RawBlock('html', html_final)
  end

} -- Fecha a tabela principal