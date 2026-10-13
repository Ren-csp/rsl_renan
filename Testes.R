
#### ============================================= ####
#### 0. PACOTES                                    ####
#### ============================================= ####


## 0.1 Instalar pacotes (só os que faltam)       ##


pacotes_necessarios <- c(
  "remotes", "devtools", "revtools", "litsearchr",
  "stringi", "stringr", "bibtex", "dplyr", "tidyr",
  "ggplot2", "ggraph", "igraph", "readr", "XML",
  "bibliometrix", "countrycode", "ggrepel"
)

# Descobrir quais estão faltando
instalados <- rownames(installed.packages())
faltantes <- setdiff(pacotes_necessarios, instalados)

if (length(faltantes) == 0) {
  cat("✅ Todos os", length(pacotes_necessarios),
      "pacotes já estão instalados. Nada a fazer.\n\n")
} else {
  cat("📦 Instalando", length(faltantes), "pacote(s):",
      paste(faltantes, collapse = ", "), "\n\n")
  install.packages(faltantes, dependencies = TRUE)
  cat("\n✅ Instalação concluída.\n\n")
}

## 0.2 LIGANDO PACOTES ##

suppressPackageStartupMessages({
  library(remotes)
  library(devtools)
  library(revtools)
  library(litsearchr)
  library(stringi)
  library(stringr)
  library(bibtex)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(ggraph)
  library(igraph)
  library(readr)
  library(XML)
  library(bibliometrix)
  library(countrycode)
  library(ggrepel)
})

cat("\n✅ Todos os pacotes carregados com sucesso.\n\n")



#### ============================================= ####
#### 1. DIRETÓRIO DE TRABALHO + PASTA RESULTADOS   ####
#### ============================================= ####

setwd("C:/Users/renan/OneDrive/Área de Trabalho/RSL")
cat("Diretório de trabalho:", getwd(), "\n\n")

## ---- Cria pasta 'Resultados' ---- ##
pasta_resultados <- file.path(getwd(), "Resultados")

if (!dir.exists(pasta_resultados)) {
  dir.create(pasta_resultados, recursive = TRUE)
  cat("📁 Pasta criada:", pasta_resultados, "\n\n")
} else {
  cat("📁 Pasta já existe:", pasta_resultados, "\n\n")
}

# Função auxiliar para montar caminhos dentro de Resultados
caminho_resultado <- function(nome_arquivo) {
  file.path(pasta_resultados, nome_arquivo)
}


#### ============================================= ####
#### 2. FUNÇÕES AUXILIARES                         ####
#### ============================================= ####

## --- 2.1 Leitura manual de BibTeX (fallback) --- ##
ler_bib_manual <- function(arquivo) {
  tryCatch({
    conteudo <- readLines(arquivo, warn = FALSE, encoding = "UTF-8")
    indices_inicio <- grep("^@", conteudo)
    if (length(indices_inicio) == 0) return(NULL)
    
    registros <- list()
    for (j in seq_along(indices_inicio)) {
      inicio <- indices_inicio[j]
      fim <- if (j < length(indices_inicio)) indices_inicio[j + 1] - 1 else length(conteudo)
      bloco <- paste(conteudo[inicio:fim], collapse = " ")
      campos <- list()
      
      padroes <- list(
        AU = 'author\\s*=\\s*[{"]([^"}]+)',
        TI = 'title\\s*=\\s*[{"]([^"}]+)',
        SO = 'journal\\s*=\\s*[{"]([^"}]+)',
        PY = 'year\\s*=\\s*[{"]([^"}]+)',
        VL = 'volume\\s*=\\s*[{"]([^"}]+)',
        NP = 'number\\s*=\\s*[{"]([^"}]+)',
        PP = 'pages\\s*=\\s*[{"]([^"}]+)',        # <<< corrigido
        AB = 'abstract\\s*=\\s*[{"]([^"}]+)',
        DE = 'keywords\\s*=\\s*[{"]([^"}]+)',
        CR = 'references\\s*=\\s*[{"]([^"}]+)',
        UT = 'doi\\s*=\\s*[{"]([^"}]+)',
        C1 = 'address\\s*=\\s*[{"]([^"}]+)'
      )
      
      for (nome in names(padroes)) {
        match <- regexpr(padroes[[nome]], bloco, ignore.case = TRUE)
        if (match[1] != -1) {
          valor <- regmatches(bloco, match)
          valor <- gsub('^[^"]*["{]|["}].*$', "", valor)
          campos[[nome]] <- trimws(valor)
        }
      }
      if (length(campos) > 0) registros[[length(registros) + 1]] <- campos
    }
    
    if (length(registros) > 0) {
      df <- do.call(rbind, lapply(registros, function(x) {
        as.data.frame(t(unlist(x)), stringsAsFactors = FALSE)
      }))
      return(df)
    } else return(NULL)
  }, error = function(e) return(NULL))
}


## --- 2.2 Importar pasta WOS (.bib via bibliometrix) --- ##
importar_pasta_wos <- function(caminho_pasta, formato = "bib") {
  if (formato == "bib") {
    arquivos <- list.files(caminho_pasta, pattern = "\\.bib$|\\.BIB$", full.names = TRUE)
  } else if (formato == "txt") {
    arquivos <- list.files(caminho_pasta, pattern = "\\.txt$|\\.TXT$", full.names = TRUE)
  } else stop("Formato não suportado.")
  
  if (length(arquivos) == 0) stop(paste("Nenhum arquivo encontrado em:", caminho_pasta))
  
  cat("Encontrados", length(arquivos), "arquivos\n")
  dados_combinados <- NULL
  
  for (i in seq_along(arquivos)) {
    cat("\n[", i, "/", length(arquivos), "] ", basename(arquivos[i]), sep = "")
    dados_temp <- NULL
    
    # Tentativa 1: bibliometrix
    tryCatch({
      cat("\n  bibliometrix...")
      dados_temp <- bibliometrix::convert2df(arquivos[i], dbsource = "wos", format = "bibtex")
      cat(" OK", nrow(dados_temp), "registros\n")
    }, error = function(e) cat("\n  ERRO bibliometrix:", e$message, "\n"))
    
    # Tentativa 2: revtools
    if (is.null(dados_temp) || nrow(dados_temp) == 0) {
      tryCatch({
        cat("  revtools...")
        dados_temp <- revtools::read_bibliography(normalizePath(arquivos[i], winslash = "/"))
        cat(" OK", nrow(dados_temp), "registros\n")
      }, error = function(e) cat("\n  ERRO revtools:", e$message, "\n"))
    }
    
    # Tentativa 3: manual
    if (is.null(dados_temp) || nrow(dados_temp) == 0) {
      cat("  manual...")
      dados_temp <- ler_bib_manual(arquivos[i])
    }
    
    if (!is.null(dados_temp) && nrow(dados_temp) > 0) {
      if (is.null(dados_combinados)) {
        dados_combinados <- dados_temp
      } else {
        colunas_comuns <- intersect(colnames(dados_combinados), colnames(dados_temp))
        dados_combinados <- dplyr::bind_rows(
          dados_combinados[, colunas_comuns, drop = FALSE],
          dados_temp[, colunas_comuns, drop = FALSE]
        )
      }
    }
  }
  
  cat("\n>>> TOTAL WOS:", nrow(dados_combinados), "registros\n")
  return(dados_combinados)
}


## --- 2.3 Padronizar para o formato do litsearchr --- ##
padronizar_para_litsearchr <- function(df, nome_database) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  
  df <- df %>% rename_with(toupper)
  
  df_padrao <- data.frame(
    title     = if ("TI" %in% names(df)) df$TI else NA_character_,
    abstract  = if ("AB" %in% names(df)) df$AB else NA_character_,
    keywords  = if ("DE" %in% names(df)) df$DE else 
      if ("ID" %in% names(df)) df$ID else NA_character_,
    author    = if ("AU" %in% names(df)) df$AU else NA_character_,
    year      = if ("PY" %in% names(df)) df$PY else 
      if ("PD" %in% names(df)) df$PD else NA_character_,
    journal   = if ("SO" %in% names(df)) df$SO else 
      if ("JI" %in% names(df)) df$JI else NA_character_,
    doi       = if ("DI" %in% names(df)) df$DI else 
      if ("UT" %in% names(df)) df$UT else NA_character_,
    country   = if ("C1" %in% names(df)) df$C1 else 
      if ("RP" %in% names(df)) df$RP else NA_character_,
    citations = if ("TC" %in% names(df)) as.numeric(df$TC) else 
      if ("Z9" %in% names(df)) as.numeric(df$Z9) else NA_real_,
    database  = nome_database,
    stringsAsFactors = FALSE
  )
  
  return(df_padrao)
}



## --- 2.4 Extrair país de uma afiliação (VETORIZADA, rápida) --- ##
extrair_pais_vetor <- function(vetor_txt) {
  
  # Para cada afiliação, tenta o último trecho (depois da última vírgula)
  # e depois o último trecho depois do último ponto e vírgula.
  candidatos <- vapply(vetor_txt, function(txt) {
    if (is.na(txt) || trimws(txt) == "") return(NA_character_)
    
    # Quebra por ";" e pega o último pedaço
    partes <- trimws(unlist(strsplit(txt, ";")))
    ultima <- tail(partes, 1)
    
    # Do último pedaço, pega o último segmento após a última vírgula
    sub_partes <- trimws(unlist(strsplit(ultima, ",")))
    candidato <- tail(sub_partes, 1)
    
    return(candidato)
  }, character(1), USE.NAMES = FALSE)
  
  # Aplicação VETORIZADA (uma única chamada para toda a coluna)
  paises <- suppressWarnings(
    countrycode::countrycode(candidatos,
                             origin = "country.name",
                             destination = "country.name",
                             warn = FALSE)
  )
  
  return(paises)
}


#### ============================================= ####
#### 3. IMPORTAÇÃO DOS DADOS                       ####
#### ============================================= ####

## ---- 3.1 WOS ---- ##
cat("\n===== IMPORTANDO WOS =====\n")
dados_WOS_raw <- importar_pasta_wos("C:/Users/renan/OneDrive/Área de Trabalho/RSL/WOS")


## ---- 3.2 Scopus ---- ##
cat("\n===== IMPORTANDO SCOPUS =====\n")
dados_SCO_raw <- bibliometrix::convert2df(
  file = "C:/Users/renan/OneDrive/Área de Trabalho/RSL/SCO/sco_todos.bib",
  dbsource = "scopus",
  format = "bibtex"
)
cat(">>> Scopus:", nrow(dados_SCO_raw), "registros\n")


#### ============================================= ####
#### 4. PADRONIZAR COLUNAS                         ####
#### ============================================= ####

dados_WOS <- padronizar_para_litsearchr(dados_WOS_raw, "WOS")
dados_SCO <- padronizar_para_litsearchr(dados_SCO_raw, "Scopus")


cat("\n--- Estrutura final ---\n")
cat("WOS:   ", nrow(dados_WOS), "registros |", ncol(dados_WOS), "colunas\n")
cat("Scopus:", nrow(dados_SCO), "registros |", ncol(dados_SCO), "colunas\n")


#### ============================================= ####
#### 5. COMBINAR WOS + SCOPUS                      ####
#### ============================================= ####

naive_results_import <- bind_rows(dados_WOS, dados_SCO)

cat("\n===== DISTRIBUIÇÃO POR BASE =====\n")
print(table(naive_results_import$database))

cat("\n===== DADOS FALTANTES =====\n")
cat("Sem título:   ", sum(is.na(naive_results_import$title)), "\n")
cat("Sem abstract: ", sum(is.na(naive_results_import$abstract)), "\n")
cat("Sem keywords: ", sum(is.na(naive_results_import$keywords)), "\n")


#### ============================================= ####
#### 5B. REMOVER ARTIGOS SEM RESUMO                ####
#### ============================================= ####

cat("\n===== REMOVENDO ARTIGOS SEM RESUMO =====\n")

n_antes <- nrow(naive_results_import)

naive_results_import <- naive_results_import %>%
  filter(
    !is.na(abstract),
    trimws(abstract) != "",
    nchar(trimws(abstract)) >= 50
  )

n_depois <- nrow(naive_results_import)
cat("Antes:  ", n_antes, "registros\n")
cat("Depois: ", n_depois, "registros\n")
cat("Removidos:", n_antes - n_depois, "\n")
cat("Retenção:", round(100 * n_depois / n_antes, 1), "%\n")

#### ============================================= ####
#### 5C. DIAGNÓSTICO DE COLUNAS                    ####
#### ============================================= ####

cat("\n========== DIAGNÓSTICO DE COLUNAS ==========\n")

colunas_obrigatorias <- c("title", "abstract", "keywords")
colunas_recomendadas <- c("author", "year", "journal",
                          "doi", "database", "country", "citations")

verificar_colunas <- function(df, nome) {
  cat("\n--- Base:", nome, "---\n")
  if (is.null(df) || nrow(df) == 0) {
    cat("  [ERRO] Base vazia ou NULL\n"); return(invisible(NULL))
  }
  cat("  Dimensões:", nrow(df), "x", ncol(df), "\n")
  
  for (col in colunas_obrigatorias) {
    if (col %in% colnames(df)) {
      n_na  <- sum(is.na(df[[col]]) | trimws(df[[col]]) == "")
      pct   <- round(100 * n_na / nrow(df), 1)
      status <- if (pct == 0) "OK" else if (pct < 20) "PARCIAL" else "CRÍTICO"
      cat(sprintf("    [%s] %-10s preenchida: %d/%d (faltando %s%%)\n",
                  status, col, nrow(df) - n_na, nrow(df), pct))
    } else {
      cat(sprintf("    [FALTANDO] %s\n", col))
    }
  }
  
  for (col in colunas_recomendadas) {
    if (col %in% colnames(df)) {
      n_na <- sum(is.na(df[[col]]) | trimws(as.character(df[[col]])) == "")
      pct  <- round(100 * n_na / nrow(df), 1)
      cat(sprintf("    [OK]      %-10s preenchida: %d/%d (faltando %s%%)\n",
                  col, nrow(df) - n_na, nrow(df), pct))
    } else {
      cat(sprintf("    [AUSENTE] %s\n", col))
    }
  }
}

verificar_colunas(dados_WOS, "WOS (padronizado)")
verificar_colunas(dados_SCO, "Scopus (padronizado)")
verificar_colunas(naive_results_import, "Combinado (após filtros)")




#### ============================================= ####
#### 6. DEDUPLICAÇÃO                               ####
#### ============================================= ####

cat("\n===== DEDUPLICANDO =====\n")
naive_results <- litsearchr::remove_duplicates(
  df = naive_results_import,
  field = "title",
  method = "exact"
)

cat("Total antes: ", nrow(naive_results_import), "\n")
cat("Total depois:", nrow(naive_results), "\n")
cat("Removidos:   ", nrow(naive_results_import) - nrow(naive_results), "\n")


#### ============================================= ####
#### 6B. TOP 10 AUTORES MAIS PRODUTIVOS            ####
#### ============================================= ####

cat("\n===== TOP 10 AUTORES MAIS PRODUTIVOS =====\n")

autores_lista <- naive_results$author %>%
  na.omit() %>%
  as.character() %>%
  strsplit(split = ";|\\band\\b") %>%
  unlist() %>%
  trimws() %>%
  .[. != ""] %>%
  toupper()

top_autores <- as.data.frame(sort(table(autores_lista), decreasing = TRUE))
colnames(top_autores) <- c("autor", "n_artigos")
top_autores <- head(top_autores, 10)

print(top_autores, row.names = FALSE)





#### ============================================= ####
#### 6C. NORMALIZAÇÃO SINGULAR/PLURAL              ####
#### ============================================= ####

cat("\n===== NORMALIZANDO SINGULAR/PLURAL =====\n")

normalizar_plural <- function(texto) {
  whitelist <- c(
    "stress", "focus", "analysis", "process", "bias", "gas", "class",
    "access", "across", "less", "this", "his", "its", "as", "is",
    "us", "was", "has", "does", "goes", "cross", "glass", "grass",
    "species", "series", "basis", "crisis", "thesis", "consensus",
    "bus", "plus", "campus", "status", "apparatus", "stimulus",
    "affect", "well-being", "wellbeing"
  )
  
  normaliza_palavra <- function(p) {
    if (nchar(p) <= 3) return(p)
    if (tolower(p) %in% whitelist) return(p)
    p <- gsub("ies$", "y", p)
    p <- gsub("sses$", "ss", p)
    p <- gsub("xes$", "x", p)
    p <- gsub("ches$", "ch", p)
    p <- gsub("shes$", "sh", p)
    p <- gsub("oes$", "o", p)
    p <- gsub("([^s])s$", "\\1", p)
    return(p)
  }
  
  vapply(texto, function(t) {
    if (is.na(t) || trimws(t) == "") return(t)
    palavras <- unlist(strsplit(t, "\\s+"))
    palavras <- vapply(palavras, normaliza_palavra, character(1))
    paste(palavras, collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

naive_results$title_norm    <- normalizar_plural(naive_results$title)
naive_results$abstract_norm <- normalizar_plural(naive_results$abstract)
naive_results$keywords_norm <- normalizar_plural(naive_results$keywords)

cat("OK Colunas *_norm criadas.\n")


#### ============================================= ####
#### 7. EXTRAÇÃO DE TERMOS (OTIMIZADA)             ####
#### ============================================= ####

cat("\n===== EXTRAINDO TERMOS =====\n")

limpar_texto <- function(x) {
  x <- as.character(x)
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub('^[\\s"\\{\\}]+', "", x)
  x <- gsub('[\\s"\\{\\}]+$', "", x)
  x <- gsub('"', "", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

# --- Limpeza ---
naive_results$title_norm    <- limpar_texto(naive_results$title_norm)
naive_results$abstract_norm <- limpar_texto(naive_results$abstract_norm)
naive_results$keywords_norm <- limpar_texto(naive_results$keywords_norm)

naive_results$title_norm[is.na(naive_results$title_norm)]       <- ""
naive_results$abstract_norm[is.na(naive_results$abstract_norm)] <- ""
naive_results$keywords_norm[is.na(naive_results$keywords_norm)] <- ""

cat("Base limpa:", nrow(naive_results), "artigos\n")

# ============================================================
# OTIMIZAÇÃO: usar amostra para extração de termos
# ============================================================
# 83k artigos é excessivo para extração de termos.
# 20k já dá resultado estatisticamente idêntico.
# Se você quer mesmo os 83k, use min_n = 2 (não 1) abaixo.

set.seed(42)
N_AMOSTRA_TERMOS <- 20000

if (nrow(naive_results) > N_AMOSTRA_TERMOS) {
  idx_amostra <- sample(nrow(naive_results), N_AMOSTRA_TERMOS)
  naive_results_termos <- naive_results[idx_amostra, ]
  cat("Amostra para extração:", N_AMOSTRA_TERMOS, "artigos\n")
} else {
  naive_results_termos <- naive_results
  cat("Usando todos os", nrow(naive_results), "artigos\n")
}

# --- [1/3] Keywords (tagged) — rápido ---
cat("\n--- [1/3] Extraindo keywords ---\n")
t0 <- Sys.time()
keywords <- litsearchr::extract_terms(
  keywords = naive_results_termos[, "keywords_norm"],
  min_freq = 3,
  method = "tagged"
)
cat("Keywords:", length(keywords), "| tempo:",
    round(difftime(Sys.time(), t0, units = "secs")), "s\n")

# --- [2/3] Title terms — moderado ---
cat("\n--- [2/3] Extraindo title terms ---\n")
t0 <- Sys.time()
title_terms <- litsearchr::extract_terms(
  text = naive_results_termos[, "title_norm"],
  method = "fakerake",
  min_freq = 3,
  min_n = 2,        # <<< min_n = 2 (era 1) → 10x mais rápido
  max_n = 4
)
cat("Title terms:", length(title_terms), "| tempo:",
    round(difftime(Sys.time(), t0, units = "secs")), "s\n")

# --- [3/3] Abstract terms — o gargalo ---
cat("\n--- [3/3] Extraindo abstract terms ---\n")
cat("⚠️  Se demorar >30min, interrompa e reduza a amostra.\n")

abstracts_ok <- naive_results_termos$abstract_norm
abstracts_ok[nchar(abstracts_ok) < 200]  <- ""
abstracts_ok[nchar(abstracts_ok) > 3000] <-
  substr(abstracts_ok[nchar(abstracts_ok) > 3000], 1, 3000)

cat("Abstracts usados:", sum(abstracts_ok != ""), "de", length(abstracts_ok), "\n")

t0 <- Sys.time()
abstract_terms <- litsearchr::extract_terms(
  text = abstracts_ok,
  method = "fakerake",
  min_freq = 5,
  min_n = 2,        # <<< AQUI está a diferença: 2 em vez de 1
  max_n = 3
)
tempo_abs <- round(difftime(Sys.time(), t0, units = "mins"), 1)
cat("Abstract terms:", length(abstract_terms),
    "| tempo:", tempo_abs, "min\n")

# --- Combinar ---
terms_full <- unique(c(keywords, title_terms, abstract_terms))
terms_full <- unique(limpar_texto(terms_full))
terms_full <- terms_full[terms_full != ""]

cat("\nTotal de termos únicos:", length(terms_full), "\n")

# --- Checkpoint ---
saveRDS(list(keywords = keywords,
             title_terms = title_terms,
             abstract_terms = abstract_terms,
             terms_full = terms_full),
        file = caminho_resultado("checkpoint_termos.rds"))
cat("Checkpoint salvo.\n")





#### ============================================= ####
#### 8. REDE DE TERMOS (versão otimizada)          ####
#### ============================================= ####



#### ============================================= ####
#### 8A. AMOSTRA                                   ####
#### ============================================= ####

cat("\n===== 8A. AMOSTRA =====\n")
cat("Artigos totais:", nrow(naive_results), "\n")

set.seed(42)
N_AMOSTRA <- 15000

if (nrow(naive_results) > N_AMOSTRA) {
  naive_results_rede <- naive_results %>% sample_n(N_AMOSTRA)
  cat("Amostra aplicada:", N_AMOSTRA, "artigos\n")
} else {
  naive_results_rede <- naive_results
  cat("Usando todos os", nrow(naive_results), "artigos\n")
}


#### ============================================= ####
#### 8B. CONTAGEM DE FREQUÊNCIA (VETORIZADA)       ####
#### ============================================= ####

cat("\n===== 8B. CONTAGEM DE FREQUÊNCIA =====\n")

docs <- paste(naive_results_rede$title_norm,
              naive_results_rede$abstract_norm,
              sep = " ")

t0 <- Sys.time()

# --- 8B.1: palavras isoladas ---
palavras_por_doc <- stringi::stri_extract_all_words(docs)
freq_palavras <- table(unlist(lapply(palavras_por_doc, unique)))

# --- 8B.2: separar single e multi ---
termos_single <- terms_full[!grepl(" ", terms_full)]
termos_multi  <- terms_full[grepl(" ", terms_full)]

cat("  Termos single:", length(termos_single),
    "| Termos multi:", length(termos_multi), "\n")

# --- 8B.3: frequência dos single ---
freq_single <- as.integer(freq_palavras[termos_single])
freq_single[is.na(freq_single)] <- 0
names(freq_single) <- termos_single

# --- 8B.4: frequência dos multi (vetorizado em BLOCOS com OR) ---
cat("  Contando multi em blocos (100 por bloco)...\n")

freq_multi <- integer(length(termos_multi))
names(freq_multi) <- termos_multi

if (length(termos_multi) > 0) {
  bloco <- 100
  n_blocos <- ceiling(length(termos_multi) / bloco)
  
  for (i in seq_len(n_blocos)) {
    ini <- (i - 1) * bloco + 1
    fim <- min(i * bloco, length(termos_multi))
    sub <- termos_multi[ini:fim]
    
    # Escape de caracteres especiais de regex
    sub_esc <- gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", sub)
    
    # Padrão OR com todos os termos do bloco
    padrao <- paste0("(?i)\\b(", paste(sub_esc, collapse = "|"), ")\\b")
    
    # stri_detect_regex: docs × 1 (TRUE se algum termo do bloco aparece)
    # Mas precisamos contar POR TERMO. Então usamos stri_match_all_regex
    # e contamos os matches.
    matches <- stringi::stri_match_all_regex(docs, padrao, omit_no_match = TRUE)
    
    # Extrair o termo casado (coluna 2 = grupo capturado)
    todos_matches <- unlist(lapply(matches, function(m) {
      if (nrow(m) == 0) return(character(0))
      m[, 2]
    }))
    
    # Contar por termo (case-insensitive)
    tab <- table(tolower(todos_matches))
    
    for (t in sub) {
      n <- tab[tolower(t)]
      freq_multi[t] <- if (is.na(n)) 0L else as.integer(n)
    }
    
    # Progresso a cada 10 blocos
    if (i %% 10 == 0 || i == n_blocos) {
      cat(sprintf("    bloco %d/%d (%.0f s)\n", i, n_blocos,
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    }
  }
}

# --- 8B.5: juntar ---
termos_freq <- c(freq_single, freq_multi)
termos_freq <- termos_freq[terms_full]
termos_freq[is.na(termos_freq)] <- 0

cat("  tempo total:", round(difftime(Sys.time(), t0, units = "secs")), "s\n")




#### ============================================= ####
#### 8C. FILTRAR TERMOS RAROS                      ####
#### ============================================= ####

cat("\n===== 8C. FILTRANDO TERMOS RAROS =====\n")

terms_filtrados <- terms_full[termos_freq >= 20]
cat("Termos antes:", length(terms_full),
    "| depois (>=20 artigos):", length(terms_filtrados), "\n")

# Se o filtro foi agressivo demais, reduzir o limiar
if (length(terms_filtrados) < 50) {
  cat("⚠️  Poucos termos. Baixando limiar para >=5...\n")
  terms_filtrados <- terms_full[termos_freq >= 5]
  cat("Termos filtrados (>=5):", length(terms_filtrados), "\n")
}


#### ============================================= ####
#### 8D. CRIAR DFM                                 ####
#### ============================================= ####

cat("\n===== 8D. CRIANDO DFM =====\n")
t0 <- Sys.time()
dfm <- litsearchr::create_dfm(elements = docs, features = terms_filtrados)
cat("DFM:", nrow(dfm), "x", ncol(dfm),
    "| tempo:", round(difftime(Sys.time(), t0, units = "secs")), "s\n")


#### ============================================= ####
#### 8E. CRIAR REDE                                ####
#### ============================================= ####

cat("\n===== 8E. CRIANDO REDE =====\n")
t0 <- Sys.time()
g <- litsearchr::create_network(dfm, min_studies = 10)
cat("Nós:", length(igraph::V(g)),
    "| Arestas:", length(igraph::E(g)),
    "| tempo:", round(difftime(Sys.time(), t0, units = "mins"), 2), "min\n")


#### ============================================= ####
#### 8F. VERIFICAÇÃO PÓS-REDE                      ####
#### ============================================= ####

cat("\n===== 8F. VERIFICAÇÃO DA REDE =====\n")

termos_alvo_check <- c("affection", "emotion", "emotional", "feeling",
                       "perception", "perceived", "place attachment",
                       "well-being", "mental health")

presentes <- termos_alvo_check[termos_alvo_check %in% igraph::V(g)$name]
ausentes  <- setdiff(termos_alvo_check, presentes)

cat("Termos-alvo presentes na rede:", length(presentes), "\n")
print(presentes)
cat("\nTermos-alvo ausentes:\n")
print(ausentes)

# Salvar checkpoint
saveRDS(list(dfm = dfm, g = g, terms_filtrados = terms_filtrados),
        file = caminho_resultado("checkpoint_rede.rds"))
cat("\n💾 Checkpoint da rede salvo em checkpoint_rede.rds\n")

# ============================================================
# 4. CRIAR DFM
# ============================================================

cat("\nCriando DFM...\n")
t0 <- Sys.time()
dfm <- litsearchr::create_dfm(elements = docs, features = terms_filtrados)
cat("DFM:", nrow(dfm), "x", ncol(dfm),
    "| tempo:", round(difftime(Sys.time(), t0, units = "secs")), "s\n")

# ============================================================
# 5. CRIAR REDE
# ============================================================

cat("\nCriando rede (min_studies = 10)...\n")
t0 <- Sys.time()
g <- litsearchr::create_network(dfm, min_studies = 10)
cat("Nós:", length(igraph::V(g)),
    "| Arestas:", length(igraph::E(g)),
    "| tempo:", round(difftime(Sys.time(), t0, units = "mins"), 2), "min\n")

# ============================================================
# 6. VERIFICAÇÃO PÓS-REDE
# ============================================================

cat("\n===== VERIFICAÇÃO DA REDE =====\n")

termos_alvo_check <- c("affection", "emotion", "emotional", "feeling",
                       "perception", "perceived", "place attachment",
                       "well-being", "mental health")

presentes <- termos_alvo_check[termos_alvo_check %in% igraph::V(g)$name]
ausentes  <- setdiff(termos_alvo_check, presentes)

cat("Termos-alvo presentes na rede:", length(presentes), "\n")
print(presentes)
cat("\nTermos-alvo ausentes:\n")
print(ausentes)

# Salvar checkpoint
saveRDS(list(dfm = dfm, g = g, terms_filtrados = terms_filtrados),
        file = caminho_resultado("checkpoint_rede.rds"))
cat("\n💾 Checkpoint da rede salvo em checkpoint_rede.rds\n")



#### ============================================= ####
#### 9. FORÇA DOS TERMOS + CLASSIFICAÇÃO TEMÁTICA  ####
#### ============================================= ####

cat("\n===== FORÇA DOS TERMOS =====\n")

term_strengths <- data.frame(
  term     = names(igraph::strength(g)),
  strength = as.numeric(igraph::strength(g)),
  stringsAsFactors = FALSE
) %>%
  mutate(rank = rank(-strength, ties.method = "min")) %>%
  arrange(desc(strength))

# --- Classificação temática (VETORIZADA, mais rápida) ---
classificar_termos_vetor <- function(termos) {
  termos_lower <- tolower(termos)
  
  # Padrões por categoria (um OR gigante por categoria)
  padroes <- list(
    Afeto = paste(c(
      "affection", "affective", "affect", "emotion", "emotional",
      "feeling", "mood", "well-being", "wellbeing", "mental health",
      "restorative", "stress", "anxiety", "satisfaction", "happiness",
      "pleasure", "preference", "aesthetic", "attachment",
      "place attachment", "place identity", "belonging"
    ), collapse = "|"),
    
    Percepção = paste(c(
      "perception", "perceived", "perceptual", "perceiv",
      "view", "opinion", "attitude", "awareness", "experience",
      "response", "preference", "judgment", "assessment"
    ), collapse = "|"),
    
    `Espaço urbano/natureza` = paste(c(
      "urban", "park", "green", "space", "nature",
      "environment", "landscape", "outdoor", "public", "open",
      "forest", "garden", "tree", "vegetation", "ecosystem",
      "built", "neighborhood", "city", "cities"
    ), collapse = "|"),
    
    `Humano/social` = paste(c(
      "human", "people", "person", "resident", "visitor",
      "user", "community", "social", "individual"
    ), collapse = "|")
  )
  
  # Classificação por prioridade (Afeto > Percepção > Espaço > Humano)
  categoria <- rep("Outro", length(termos))
  
  # Ordem importa (último a sobrescrever ganha, então processamos ao contrário)
  for (cat_nome in c("Humano/social", "Espaço urbano/natureza",
                     "Percepção", "Afeto")) {
    idx <- grepl(padroes[[cat_nome]], termos_lower)
    categoria[idx] <- cat_nome
  }
  
  return(categoria)
}

term_strengths$categoria <- classificar_termos_vetor(term_strengths$term)

cat("\n===== DISTRIBUIÇÃO POR CATEGORIA =====\n")
print(table(term_strengths$categoria))

cat("\n===== TOP 30 GERAL =====\n")
print(head(term_strengths, 30), row.names = FALSE)

cat("\n===== TOP 30 — AFETO =====\n")
print(head(term_strengths %>% filter(categoria == "Afeto"), 30), row.names = FALSE)

cat("\n===== TOP 30 — PERCEPÇÃO =====\n")
print(head(term_strengths %>% filter(categoria == "Percepção"), 30), row.names = FALSE)

write.csv(term_strengths,
          caminho_resultado("termos_forca_classificados.csv"),
          row.names = FALSE)


#### ============================================= ####
#### 9B. DISTÂNCIA DOS TERMOS-ALVO                 ####
#### ============================================= ####

cat("\n===== DISTÂNCIA DE TERMOS-CHAVE =====\n")

termos_alvo_afeto <- c("affection", "affective", "emotion", "emotional",
                       "feeling", "mood", "well-being", "mental health",
                       "place attachment", "restorative")

termos_alvo_percep <- c("perception", "perceived", "perceptual",
                        "environmental perception", "attitude",
                        "preference", "experience", "awareness")

todos_alvos <- unique(c(termos_alvo_afeto, termos_alvo_percep))
presentes   <- todos_alvos[todos_alvos %in% igraph::V(g)$name]
ausentes    <- setdiff(todos_alvos, presentes)

cat("Presentes:", length(presentes), "| Ausentes:", length(ausentes), "\n")
cat("Presentes:\n"); print(presentes)
cat("\nAusentes:\n"); print(ausentes)

if (length(presentes) == 0) {
  stop("Nenhum termo-alvo está na rede.")
}

dist_mat <- igraph::distances(g, v = presentes, to = igraph::V(g)$name)

dist_df <- as.data.frame(dist_mat) %>%
  tibble::rownames_to_column(var = "termo_alvo") %>%
  tidyr::pivot_longer(
    cols = -termo_alvo,
    names_to = "termo_vizinho",
    values_to = "distancia"
  ) %>%
  filter(!is.infinite(distancia), termo_alvo != termo_vizinho)

top_proximos <- dist_df %>%
  group_by(termo_alvo) %>%
  arrange(distancia) %>%
  slice_head(n = 15) %>%
  ungroup()

for (alvo in presentes) {
  cat("\n>>>", toupper(alvo), "<<<\n")
  sub <- top_proximos %>% filter(termo_alvo == alvo)
  for (i in seq_len(nrow(sub))) {
    cat(sprintf("  %2d. %-35s (dist=%d)\n",
                i, sub$termo_vizinho[i], sub$distancia[i]))
  }
}

write.csv(dist_df,      caminho_resultado("distancias_termos_alvo.csv"),      row.names = FALSE)
write.csv(top_proximos, caminho_resultado("top15_proximos_termos_alvo.csv"), row.names = FALSE)


#### ============================================= ####
#### 9. FORÇA DOS TERMOS + CLASSIFICAÇÃO TEMÁTICA  ####
#### ============================================= ####

cat("\n===== FORÇA DOS TERMOS =====\n")

term_strengths <- data.frame(
  term     = names(igraph::strength(g)),
  strength = as.numeric(igraph::strength(g)),
  stringsAsFactors = FALSE
) %>%
  mutate(rank = rank(-strength, ties.method = "min")) %>%
  arrange(desc(strength))

# --- Classificação temática (VETORIZADA, mais rápida) ---
classificar_termos_vetor <- function(termos) {
  termos_lower <- tolower(termos)
  
  # Padrões por categoria (um OR gigante por categoria)
  padroes <- list(
    Afeto = paste(c(
      "affection", "affective", "affect", "emotion", "emotional",
      "feeling", "mood", "well-being", "wellbeing", "mental health",
      "restorative", "stress", "anxiety", "satisfaction", "happiness",
      "pleasure", "preference", "aesthetic", "attachment",
      "place attachment", "place identity", "belonging"
    ), collapse = "|"),
    
    Percepção = paste(c(
      "perception", "perceived", "perceptual", "perceiv",
      "view", "opinion", "attitude", "awareness", "experience",
      "response", "preference", "judgment", "assessment"
    ), collapse = "|"),
    
    `Espaço urbano/natureza` = paste(c(
      "urban", "park", "green", "space", "nature",
      "environment", "landscape", "outdoor", "public", "open",
      "forest", "garden", "tree", "vegetation", "ecosystem",
      "built", "neighborhood", "city", "cities"
    ), collapse = "|"),
    
    `Humano/social` = paste(c(
      "human", "people", "person", "resident", "visitor",
      "user", "community", "social", "individual"
    ), collapse = "|")
  )
  
  # Classificação por prioridade (Afeto > Percepção > Espaço > Humano)
  categoria <- rep("Outro", length(termos))
  
  # Ordem importa (último a sobrescrever ganha, então processamos ao contrário)
  for (cat_nome in c("Humano/social", "Espaço urbano/natureza",
                     "Percepção", "Afeto")) {
    idx <- grepl(padroes[[cat_nome]], termos_lower)
    categoria[idx] <- cat_nome
  }
  
  return(categoria)
}

term_strengths$categoria <- classificar_termos_vetor(term_strengths$term)

cat("\n===== DISTRIBUIÇÃO POR CATEGORIA =====\n")
print(table(term_strengths$categoria))

cat("\n===== TOP 30 GERAL =====\n")
print(head(term_strengths, 30), row.names = FALSE)

cat("\n===== TOP 30 — AFETO =====\n")
print(head(term_strengths %>% filter(categoria == "Afeto"), 30), row.names = FALSE)

cat("\n===== TOP 30 — PERCEPÇÃO =====\n")
print(head(term_strengths %>% filter(categoria == "Percepção"), 30), row.names = FALSE)

write.csv(term_strengths,
          caminho_resultado("termos_forca_classificados.csv"),
          row.names = FALSE)


#### ============================================= ####
#### 9G. PONTES ENTRE AFETO E PERCEPÇÃO            ####
#### ============================================= ####

cat("\n===== PONTES ENTRE AFETO E PERCEPÇÃO =====\n")

# Subconjuntos por categoria
termos_afeto    <- term_strengths %>% filter(categoria == "Afeto")     %>% pull(term)
termos_percep   <- term_strengths %>% filter(categoria == "Percepção") %>% pull(term)

# Interseção com a rede
termos_afeto_g  <- intersect(termos_afeto,  igraph::V(g)$name)
termos_percep_g <- intersect(termos_percep, igraph::V(g)$name)

cat("Termos de afeto na rede:", length(termos_afeto_g), "\n")
cat("Termos de percepção na rede:", length(termos_percep_g), "\n")

# Arestas entre afeto e percepção
arestas <- igraph::as_data_frame(g, what = "edges")

pontes <- arestas %>%
  filter(
    (from %in% termos_afeto_g  & to %in% termos_percep_g) |
      (from %in% termos_percep_g & to %in% termos_afeto_g)
  ) %>%
  arrange(desc(weight))

cat("\nPares afeto↔percepção:", nrow(pontes), "\n")
print(head(pontes, 30), row.names = FALSE)

write.csv(pontes,
          caminho_resultado("pontes_afeto_percepcao.csv"),
          row.names = FALSE)



#### ============================================= ####
#### 9G1. TOP 10 PAÍSES MAIS PRODUTIVOS             ####
#### ============================================= ####

cat("\n===== TOP 10 PAÍSES MAIS PRODUTIVOS =====\n")

naive_results$pais <- extrair_pais_vetor(naive_results$country)

n_pais_ok <- sum(!is.na(naive_results$pais))
n_pais_na <- sum(is.na(naive_results$pais))
cat("Países identificados:", n_pais_ok, "de", nrow(naive_results), "\n")
cat("Não identificados:   ", n_pais_na, "\n\n")

top_paises <- as.data.frame(
  sort(table(naive_results$pais, useNA = "no"), decreasing = TRUE)
)
colnames(top_paises) <- c("pais", "n_artigos")
top_paises <- head(top_paises, 10)
print(top_paises, row.names = FALSE)


#### ============================================= ####
#### 9G2. NORTE × SUL GLOBAL                        ####
#### ============================================= ####

cat("\n===== NORTE × SUL GLOBAL =====\n")

paises_norte <- c(
  "United States", "Canada",
  "United Kingdom", "Germany", "France", "Italy", "Spain", "Portugal",
  "Netherlands", "Belgium", "Switzerland", "Austria", "Sweden", "Norway",
  "Denmark", "Finland", "Ireland", "Iceland", "Luxembourg", "Greece",
  "Poland", "Czech Republic", "Czechia", "Hungary", "Slovakia", "Slovenia",
  "Estonia", "Latvia", "Lithuania", "Croatia", "Romania", "Bulgaria",
  "Japan", "South Korea", "Korea, Republic of", "Australia", "New Zealand",
  "Israel", "Singapore", "Hong Kong", "Taiwan", "Russia", "Russian Federation"
)

naive_results$regiao <- ifelse(
  naive_results$pais %in% paises_norte, "Norte Global",
  ifelse(is.na(naive_results$pais), NA, "Sul Global")
)

regiao_tab <- as.data.frame(table(naive_results$regiao, useNA = "no"))
colnames(regiao_tab) <- c("regiao", "n_artigos")
print(regiao_tab, row.names = FALSE)


#### ============================================= ####
#### 9G3 TOP PAÍSES COM CORES POR REGIÃO          ####
#### ============================================= ####

cat("\n===== GRÁFICO: TOP 15 PAÍSES (Norte × Sul) =====\n")

top15_paises <- as.data.frame(
  sort(table(naive_results$pais, useNA = "no"), decreasing = TRUE)
)
colnames(top15_paises) <- c("pais", "n_artigos")
top15_paises <- head(top15_paises, 15)
top15_paises$regiao <- ifelse(top15_paises$pais %in% paises_norte,
                              "Norte Global", "Sul Global")

p_paises <- ggplot(top15_paises,
                   aes(x = reorder(pais, n_artigos),
                       y = n_artigos,
                       fill = regiao)) +
  geom_col() +
  geom_text(aes(label = n_artigos), hjust = -0.2, size = 3.5) +
  coord_flip() +
  scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                               "Sul Global"   = "#d62728")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Top 15 países produtores: Norte Global × Sul Global",
       x = NULL, y = "Número de artigos", fill = "Região") +
  theme_minimal(base_size = 13)

ggsave(caminho_resultado("top15_paises_norte_sul.png"),
       plot = p_paises, width = 10, height = 8, dpi = 300)
cat("OK top15_paises_norte_sul.png\n")

p_regiao_agg <- ggplot(regiao_tab, aes(x = regiao, y = n_artigos, fill = regiao)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = n_artigos), vjust = -0.5, size = 5) +
  scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                               "Sul Global"   = "#d62728")) +
  labs(title = "Produção total: Norte Global × Sul Global",
       x = NULL, y = "Número de artigos") +
  theme_minimal(base_size = 14)

ggsave(caminho_resultado("producao_norte_sul.png"),
       plot = p_regiao_agg, width = 8, height = 6, dpi = 300)
cat("OK producao_norte_sul.png\n")


#### ============================================= ####
#### 9G4. TERMOS POR PAÍS (CACHE OTIMIZADO)       ####
#### ============================================= ####

cat("\n===== TERMOS POR PAÍS =====\n")

# ============================================================
# OTIMIZAÇÃO: usar amostra + filtrar termos
# ============================================================

# --- 1. Amostra de artigos (15k já é representativo) ---
set.seed(42)
N_AMOSTRA_PAIS <- 15000

if (nrow(naive_results) > N_AMOSTRA_PAIS) {
  idx_amostra <- sample(nrow(naive_results), N_AMOSTRA_PAIS)
  naive_paises <- naive_results[idx_amostra, ]
  cat("Amostra aplicada:", N_AMOSTRA_PAIS, "artigos\n")
} else {
  naive_paises <- naive_results
  cat("Usando todos os", nrow(naive_results), "artigos\n")
}

# --- 2. Filtrar para os top 5000 termos ---
top_termos_pais <- term_strengths %>%
  head(5000) %>%
  pull(term)

top_termos_pais <- intersect(top_termos_pais, terms_full)
cat("Termos usados:", length(top_termos_pais),
    "de", length(terms_full), "\n")

# --- 3. Criar matriz termo × documento ---
cat("Pré-computando matriz termo × documento...\n")
t0 <- Sys.time()

docs_full <- paste(naive_paises$title_norm,
                   naive_paises$abstract_norm,
                   sep = " ")

termo_doc_mat <- matrix(FALSE,
                        nrow = length(docs_full),
                        ncol = length(top_termos_pais))
colnames(termo_doc_mat) <- top_termos_pais

# Processar em blocos
bloco <- 200
n_blocos <- ceiling(length(top_termos_pais) / bloco)

for (i in seq_len(n_blocos)) {
  ini <- (i - 1) * bloco + 1
  fim <- min(i * bloco, length(top_termos_pais))
  sub_termos <- top_termos_pais[ini:fim]
  
  for (t in sub_termos) {
    termo_doc_mat[, t] <- stringi::stri_detect_fixed(docs_full, t,
                                                     case_insensitive = TRUE)
  }
  
  if (i %% 5 == 0 || i == n_blocos) {
    cat(sprintf("  bloco %d/%d (%.0f s)\n", i, n_blocos,
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  }
}

cat("Matriz:", nrow(termo_doc_mat), "x", ncol(termo_doc_mat),
    "| tempo:", round(difftime(Sys.time(), t0, units = "mins"), 1), "min\n")

# --- 4. Função rápida de agregação ---
top_termos_subset_fast <- function(idx, n = 15, apenas_categoria = NULL) {
  if (length(idx) == 0) return(data.frame(termo = character(0), n = integer(0)))
  
  contagens <- colSums(termo_doc_mat[idx, , drop = FALSE])
  
  df <- data.frame(termo = names(contagens),
                   n = as.integer(contagens),
                   stringsAsFactors = FALSE) %>%
    filter(n > 0)
  
  if (!is.null(apenas_categoria) && exists("term_strengths")) {
    termos_cat <- term_strengths %>%
      filter(categoria == apenas_categoria) %>%
      pull(term)
    df <- df %>% filter(termo %in% termos_cat)
  }
  
  df %>% arrange(desc(n)) %>% head(n)
}

# --- 5. Metadados ---
meta_pais <- data.frame(
  pais   = naive_paises$pais,
  regiao = naive_paises$regiao,
  stringsAsFactors = FALSE
)

# --- 6. Top 5 países ---
top5_paises <- head(top15_paises$pais, 5)

# --- 7. Termos gerais por país ---
cat("\n--- TOP 10 TERMOS GERAIS POR PAÍS ---\n")
termos_gerais_pais <- list()
for (p in top5_paises) {
  idx_p <- which(meta_pais$pais == p)
  tt <- top_termos_subset_fast(idx_p, n = 10)
  termos_gerais_pais[[p]] <- tt
  cat("\n>>>", p, "(", length(idx_p), "artigos ) <<<\n")
  print(tt, row.names = FALSE)
}

# --- 8. Termos de AFETO por país ---
cat("\n--- TOP 10 TERMOS DE AFETO POR PAÍS ---\n")
termos_afeto_pais <- list()
for (p in top5_paises) {
  idx_p <- which(meta_pais$pais == p)
  tt <- top_termos_subset_fast(idx_p, n = 10, apenas_categoria = "Afeto")
  termos_afeto_pais[[p]] <- tt
  cat("\n>>>", p, "<<<\n")
  if (nrow(tt) > 0) print(tt, row.names = FALSE) else cat("  (sem termos de afeto)\n")
}

# --- 9. Termos de PERCEPÇÃO por país ---
cat("\n--- TOP 10 TERMOS DE PERCEPÇÃO POR PAÍS ---\n")
termos_percep_pais <- list()
for (p in top5_paises) {
  idx_p <- which(meta_pais$pais == p)
  tt <- top_termos_subset_fast(idx_p, n = 10, apenas_categoria = "Percepção")
  termos_percep_pais[[p]] <- tt
  cat("\n>>>", p, "<<<\n")
  if (nrow(tt) > 0) print(tt, row.names = FALSE) else cat("  (sem termos de percepção)\n")
}


#### ============================================= ####
#### 9G5. TERMOS NORTE × SUL (cache)              ####
#### ============================================= ####

cat("\n===== TERMOS NORTE × SUL GLOBAL =====\n")

top_termos_regiao_fast <- function(regiao_nome, n = 15, apenas_categoria = NULL) {
  idx <- which(meta_pais$regiao == regiao_nome)
  top_termos_subset_fast(idx, n = n, apenas_categoria = apenas_categoria)
}

# --- Gerais ---
norte_top <- top_termos_regiao_fast("Norte Global", n = 15)
sul_top   <- top_termos_regiao_fast("Sul Global",   n = 15)

df_comp <- bind_rows(
  norte_top %>% mutate(regiao = "Norte Global"),
  sul_top   %>% mutate(regiao = "Sul Global")
)

n_norte <- sum(meta_pais$regiao == "Norte Global", na.rm = TRUE)
n_sul   <- sum(meta_pais$regiao == "Sul Global",   na.rm = TRUE)

df_comp <- df_comp %>%
  mutate(
    n_artigos_regiao = ifelse(regiao == "Norte Global", n_norte, n_sul),
    taxa_por_1000 = round(1000 * n / n_artigos_regiao, 2)
  )

p_termos_reg <- ggplot(df_comp,
                       aes(x = reorder(termo, taxa_por_1000),
                           y = taxa_por_1000,
                           fill = regiao)) +
  geom_col(position = position_dodge(width = 0.8)) +
  coord_flip() +
  scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                               "Sul Global"   = "#d62728")) +
  labs(title = "Top 15 termos gerais: Norte × Sul Global",
       subtitle = "Taxa por 1.000 artigos em cada região",
       x = NULL, y = "Taxa por 1.000 artigos", fill = "Região") +
  theme_minimal(base_size = 12)

ggsave(caminho_resultado("termos_gerais_norte_sul.png"),
       plot = p_termos_reg, width = 12, height = 8, dpi = 300)
cat("OK termos_gerais_norte_sul.png\n")

# --- Afeto ---
norte_afeto <- top_termos_regiao_fast("Norte Global", n = 15, apenas_categoria = "Afeto")
sul_afeto   <- top_termos_regiao_fast("Sul Global",   n = 15, apenas_categoria = "Afeto")

df_afeto <- bind_rows(
  norte_afeto %>% mutate(regiao = "Norte Global"),
  sul_afeto   %>% mutate(regiao = "Sul Global")
) %>%
  mutate(
    n_artigos_regiao = ifelse(regiao == "Norte Global", n_norte, n_sul),
    taxa_por_1000 = round(1000 * n / n_artigos_regiao, 2)
  )

if (nrow(df_afeto) > 0) {
  p_afeto_reg <- ggplot(df_afeto,
                        aes(x = reorder(termo, taxa_por_1000),
                            y = taxa_por_1000,
                            fill = regiao)) +
    geom_col(position = position_dodge(width = 0.8)) +
    coord_flip() +
    scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                                 "Sul Global"   = "#d62728")) +
    labs(title = "Termos de AFETO: Norte × Sul Global",
         subtitle = "Taxa por 1.000 artigos",
         x = NULL, y = "Taxa por 1.000 artigos", fill = "Região") +
    theme_minimal(base_size = 12)
  
  ggsave(caminho_resultado("termos_afeto_norte_sul.png"),
         plot = p_afeto_reg, width = 12, height = 8, dpi = 300)
  cat("OK termos_afeto_norte_sul.png\n")
}

# --- Percepção ---
norte_percep <- top_termos_regiao_fast("Norte Global", n = 15, apenas_categoria = "Percepção")
sul_percep   <- top_termos_regiao_fast("Sul Global",   n = 15, apenas_categoria = "Percepção")

df_percep <- bind_rows(
  norte_percep %>% mutate(regiao = "Norte Global"),
  sul_percep   %>% mutate(regiao = "Sul Global")
) %>%
  mutate(
    n_artigos_regiao = ifelse(regiao == "Norte Global", n_norte, n_sul),
    taxa_por_1000 = round(1000 * n / n_artigos_regiao, 2)
  )

if (nrow(df_percep) > 0) {
  p_percep_reg <- ggplot(df_percep,
                         aes(x = reorder(termo, taxa_por_1000),
                             y = taxa_por_1000,
                             fill = regiao)) +
    geom_col(position = position_dodge(width = 0.8)) +
    coord_flip() +
    scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                                 "Sul Global"   = "#d62728")) +
    labs(title = "Termos de PERCEPÇÃO: Norte × Sul Global",
         subtitle = "Taxa por 1.000 artigos",
         x = NULL, y = "Taxa por 1.000 artigos", fill = "Região") +
    theme_minimal(base_size = 12)
  
  ggsave(caminho_resultado("termos_percepcao_norte_sul.png"),
         plot = p_percep_reg, width = 12, height = 8, dpi = 300)
  cat("OK termos_percepcao_norte_sul.png\n")
}


#### ============================================= ####
#### 9G6 AUTORES POR REGIÃO                      ####
#### ============================================= ####

cat("\n===== AUTORES POR REGIÃO =====\n")

autores_por_regiao <- function(regiao_nome, n = 15) {
  df_r <- naive_results %>% filter(regiao == regiao_nome)
  
  autores <- df_r$author %>%
    na.omit() %>%
    as.character() %>%
    strsplit(split = ";|\\band\\b") %>%
    unlist() %>%
    trimws() %>%
    .[. != ""] %>%
    toupper()
  
  df <- as.data.frame(sort(table(autores), decreasing = TRUE))
  colnames(df) <- c("autor", "n_artigos")
  head(df, n)
}

top_autores_norte <- autores_por_regiao("Norte Global", n = 15)
top_autores_sul   <- autores_por_regiao("Sul Global",   n = 15)

cat("\n--- TOP 15 AUTORES — NORTE GLOBAL ---\n")
print(top_autores_norte, row.names = FALSE)

cat("\n--- TOP 15 AUTORES — SUL GLOBAL ---\n")
print(top_autores_sul, row.names = FALSE)

write.csv(top_autores_norte,
          caminho_resultado("top15_autores_norte.csv"), row.names = FALSE)
write.csv(top_autores_sul,
          caminho_resultado("top15_autores_sul.csv"), row.names = FALSE)


#### ============================================= ####
#### 9G7 REVISTAS POR REGIÃO                     ####
#### ============================================= ####

cat("\n===== REVISTAS POR REGIÃO =====\n")

revistas_por_regiao <- function(regiao_nome, n = 15) {
  df_r <- naive_results %>% filter(regiao == regiao_nome)
  
  rev <- df_r$journal %>%
    na.omit() %>%
    as.character() %>%
    trimws() %>%
    .[. != ""] %>%
    toupper()
  
  df <- as.data.frame(sort(table(rev), decreasing = TRUE))
  colnames(df) <- c("revista", "n_artigos")
  head(df, n)
}

top_revistas_norte <- revistas_por_regiao("Norte Global", n = 15)
top_revistas_sul   <- revistas_por_regiao("Sul Global",   n = 15)

cat("\n--- TOP 15 REVISTAS — NORTE GLOBAL ---\n")
print(top_revistas_norte, row.names = FALSE)

cat("\n--- TOP 15 REVISTAS — SUL GLOBAL ---\n")
print(top_revistas_sul, row.names = FALSE)

write.csv(top_revistas_norte,
          caminho_resultado("top15_revistas_norte.csv"), row.names = FALSE)
write.csv(top_revistas_sul,
          caminho_resultado("top15_revistas_sul.csv"), row.names = FALSE)


#### ============================================= ####
#### 9G8 ÁREAS DO CONHECIMENTO                   ####
#### ============================================= ####

cat("\n===== ÁREAS DO CONHECIMENTO =====\n")

# WOS e Scopus trazem 'WC' (Web of Science Categories) ou 'SC' (Scopus Categories)
# quando importados via bibliometrix. Verifique se estão disponíveis:

if ("WC" %in% colnames(dados_WOS_raw)) {
  areas_wos <- dados_WOS_raw$WC %>%
    na.omit() %>%
    as.character() %>%
    strsplit(";") %>%
    unlist() %>%
    trimws() %>%
    .[. != ""]
  
  top_areas_wos <- as.data.frame(sort(table(areas_wos), decreasing = TRUE))
  colnames(top_areas_wos) <- c("area", "n")
  top_areas_wos <- head(top_areas_wos, 20)
  
  cat("\n--- TOP 20 ÁREAS (WOS) ---\n")
  print(top_areas_wos, row.names = FALSE)
  
  write.csv(top_areas_wos,
            caminho_resultado("top20_areas_wos.csv"), row.names = FALSE)
}

if ("SC" %in% colnames(dados_SCO_raw)) {
  areas_sco <- dados_SCO_raw$SC %>%
    na.omit() %>%
    as.character() %>%
    strsplit(";") %>%
    unlist() %>%
    trimws() %>%
    .[. != ""]
  
  top_areas_sco <- as.data.frame(sort(table(areas_sco), decreasing = TRUE))
  colnames(top_areas_sco) <- c("area", "n")
  top_areas_sco <- head(top_areas_sco, 20)
  
  cat("\n--- TOP 20 ÁREAS (Scopus) ---\n")
  print(top_areas_sco, row.names = FALSE)
  
  write.csv(top_areas_sco,
            caminho_resultado("top20_areas_scopus.csv"), row.names = FALSE)
}

# --- Gráfico: áreas por região (usando keywords como proxy) ---
cat("\n--- ÁREAS ESTIMADAS POR REGIÃO (via keywords) ---\n")

areas_categoria <- function(df, categoria_nome) {
  termos_cat <- if (exists("term_strengths")) {
    term_strengths %>% filter(categoria == categoria_nome) %>% pull(term)
  } else character(0)
  
  if (length(termos_cat) == 0) return(0)
  
  docs_sub <- paste(df$title, df$abstract, df$keywords, sep = " ")
  sum(sapply(termos_cat, function(t) {
    sum(grepl(paste0("\\b", t, "\\b"), docs_sub, ignore.case = TRUE))
  }))
}

norte_df <- naive_results %>% filter(regiao == "Norte Global")
sul_df   <- naive_results %>% filter(regiao == "Sul Global")

categorias <- c("Afeto", "Percepção", "Espaço urbano/natureza", "Humano/social")

df_cat_reg <- data.frame(
  categoria = categorias,
  Norte     = sapply(categorias, function(c) areas_categoria(norte_df, c)),
  Sul       = sapply(categorias, function(c) areas_categoria(sul_df,   c))
) %>%
  tidyr::pivot_longer(cols = c(Norte, Sul),
                      names_to = "regiao",
                      values_to = "n") %>%
  mutate(regiao = ifelse(regiao == "Norte", "Norte Global", "Sul Global"))

p_cat_reg <- ggplot(df_cat_reg,
                    aes(x = reorder(categoria, n),
                        y = n,
                        fill = regiao)) +
  geom_col(position = position_dodge(width = 0.8)) +
  coord_flip() +
  scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                               "Sul Global"   = "#d62728")) +
  labs(title = "Presença de categorias temáticas: Norte × Sul Global",
       x = NULL, y = "Nº de ocorrências", fill = "Região") +
  theme_minimal(base_size = 13)

ggsave(caminho_resultado("categorias_norte_sul.png"),
       plot = p_cat_reg, width = 10, height = 7, dpi = 300)
cat("OK categorias_norte_sul.png\n")




#### ============================================= ####
#### 9H. TERMOS PONTE (VETORIZADO)                 ####
#### ============================================= ####

cat("\n===== TERMOS PONTE =====\n")

termos_afeto_g  <- intersect(term_strengths$term[term_strengths$categoria == "Afeto"],
                             igraph::V(g)$name)
termos_percep_g <- intersect(term_strengths$term[term_strengths$categoria == "Percepção"],
                             igraph::V(g)$name)

cat("Termos de afeto na rede:", length(termos_afeto_g), "\n")
cat("Termos de percepção na rede:", length(termos_percep_g), "\n")

# --- Usar lista de adjacência (mais rápido que neighbors() em loop) ---
adj_list <- igraph::as_adj_list(g)

# Setar TRUE para afeto/percepção
is_afeto  <- igraph::V(g)$name %in% termos_afeto_g
is_percep <- igraph::V(g)$name %in% termos_percep_g

pontes_score <- t(sapply(seq_along(adj_list), function(i) {
  viz_idx <- as.integer(adj_list[[i]])
  c(n_afeto    = sum(is_afeto[viz_idx]),
    n_percepcao = sum(is_percep[viz_idx]))
}))

pontes_score_df <- data.frame(
  termo       = igraph::V(g)$name,
  n_afeto     = pontes_score[, "n_afeto"],
  n_percepcao = pontes_score[, "n_percepcao"],
  score_ponte = pontes_score[, "n_afeto"] + pontes_score[, "n_percepcao"],
  stringsAsFactors = FALSE
) %>%
  arrange(desc(score_ponte))

cat("\nTop 30 termos que mais conectam afeto e percepção:\n")
print(head(pontes_score_df, 30), row.names = FALSE)

write.csv(pontes_score_df,
          caminho_resultado("termos_ponte_afeto_percepcao.csv"),
          row.names = FALSE)


#### ============================================= ####
#### 10. CUTOFF (80% cumulativo)                   ####
#### ============================================= ####

cutoff_cumul <- litsearchr::find_cutoff(g, method = "cumulative", percent = 0.8)
cat("\nCutoff cumulativo (80%):", cutoff_cumul, "\n")

kept_terms <- term_strengths %>%
  filter(strength >= cutoff_cumul) %>%
  pull(term)

cat("Termos mantidos:", length(kept_terms), "\n")


#### ============================================= ####
#### 11. SOBREPOSIÇÃO WOS × SCOPUS                 ####
#### ============================================= ####

titulos_wos <- tolower(trimws(dados_WOS$title))
titulos_sco <- tolower(trimws(dados_SCO$title))

only_wos <- setdiff(titulos_wos, titulos_sco)
only_sco <- setdiff(titulos_sco, titulos_wos)
both     <- intersect(titulos_wos, titulos_sco)


#### ============================================= ####
#### 12. EXPORTAÇÕES E GRÁFICOS                    ####
#### ============================================= ####

cat("\n===== EXPORTANDO RESULTADOS =====\n")

write.csv(term_strengths,       caminho_resultado("termos_forca.csv"),       row.names = FALSE)
write.csv(data.frame(termo = kept_terms),
          caminho_resultado("termos_finais.csv"),      row.names = FALSE)
write.csv(naive_results,        caminho_resultado("estudos_deduplicados.csv"), row.names = FALSE)
write.csv(top_autores,          caminho_resultado("top10_autores.csv"),      row.names = FALSE)
write.csv(top_paises,           caminho_resultado("top10_paises.csv"),       row.names = FALSE)
write.csv(regiao_tab,           caminho_resultado("producao_por_regiao.csv"), row.names = FALSE)

dados_sobreposicao <- data.frame(
  categoria = c("Só WOS", "Só Scopus", "Em ambas"),
  n = c(length(only_wos), length(only_sco), length(both))
)
write.csv(dados_sobreposicao,   caminho_resultado("sobreposicao_bases.csv"), row.names = FALSE)

write.csv(top_paises,           caminho_resultado("top10_paises.csv"),       row.names = FALSE)
write.csv(regiao_tab,           caminho_resultado("producao_por_regiao.csv"), row.names = FALSE)

## ---- 12.1 Curva de cutoff colorida por categoria ---- ##

cat("\n===== GRÁFICO: CURVA DE CUTOFF =====\n")

n_rotulos <- 20
term_strengths_plot <- term_strengths %>%
  mutate(label = ifelse(rank <= n_rotulos, term, NA_character_))

cores_categoria <- c(
  "Afeto"                 = "#d62728",
  "Percepção"             = "#1f77b4",
  "Espaço urbano/natureza" = "#2ca02c",
  "Humano/social"         = "#ff7f0e",
  "Outro"                 = "gray60"
)

p_cutoff <- ggplot(term_strengths_plot, aes(x = rank, y = strength)) +
  geom_rect(aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = cutoff_cumul),
            fill = "#ffe5e5", alpha = 0.4, inherit.aes = FALSE) +
  geom_line(color = "gray40", linewidth = 0.6) +
  geom_point(aes(color = categoria), size = 2.5) +
  geom_hline(yintercept = cutoff_cumul, linetype = "dashed",
             color = "#d62728", linewidth = 0.9) +
  geom_text_repel(aes(label = label, color = categoria),
                  size = 3.5, fontface = "bold",
                  box.padding = 0.4, max.overlaps = 20,
                  direction = "y", nudge_x = 30, hjust = 0,
                  na.rm = TRUE) +
  scale_color_manual(values = cores_categoria, name = "Categoria") +
  scale_x_continuous(limits = c(0, max(term_strengths$rank)),
                     expand = c(0.02, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.1))) +
  labs(
    title = "Força dos termos por categoria temática",
    subtitle = paste0("Total: ", nrow(term_strengths), " termos | ",
                      "Artigos: ", nrow(naive_results_rede)),
    x = "Ranking", y = "Força (strength)"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

ggsave(caminho_resultado("curva_cutoff_categorizada.png"),
       plot = p_cutoff, width = 14, height = 8, dpi = 300)


## ---- 12.2 Top 30 termos por categoria ---- ##

cat("\n===== GRÁFICOS POR CATEGORIA =====\n")

for (cat_nome in c("Afeto", "Percepção", "Espaço urbano/natureza", "Humano/social")) {
  df_cat <- term_strengths %>%
    filter(categoria == cat_nome) %>%
    head(30)
  
  if (nrow(df_cat) == 0) next
  
  p_cat <- ggplot(df_cat, aes(x = reorder(term, strength), y = strength)) +
    geom_col(fill = cores_categoria[cat_nome]) +
    coord_flip() +
    labs(title = paste("Top 30 termos —", cat_nome),
         x = NULL, y = "Força (strength)") +
    theme_minimal(base_size = 12)
  
  ggsave(caminho_resultado(paste0("top30_", gsub("/", "_", cat_nome), ".png")),
         plot = p_cat, width = 10, height = 9, dpi = 300)
}


## ---- 12.3 Rede com categorias coloridas ---- ##

cat("\n===== REDE COLORIDA POR CATEGORIA =====\n")

top_n <- 100
top_terms <- term_strengths %>% head(top_n) %>% pull(term)
g_top <- igraph::induced_subgraph(g, vids = top_terms)

peso_min <- quantile(igraph::E(g_top)$weight, 0.3)
g_top <- igraph::delete_edges(g_top,
                              igraph::E(g_top)[igraph::E(g_top)$weight < peso_min])

V(g_top)$categoria <- term_strengths$categoria[match(V(g_top)$name, term_strengths$term)]

set.seed(42)
p_rede_cat <- ggraph(g_top, layout = "fr") +
  geom_edge_link(aes(alpha = weight, width = weight),
                 color = "gray70", show.legend = FALSE) +
  scale_edge_width(range = c(0.2, 1.2)) +
  geom_node_point(aes(color = categoria), size = 3.5) +
  geom_node_text(aes(label = name), repel = TRUE, size = 2.8,
                 bg.color = "white", bg.r = 0.15, max.overlaps = 30) +
  scale_color_manual(values = cores_categoria, name = "Categoria") +
  labs(title = paste("Rede de termos — top", top_n, "por categoria"),
       subtitle = paste(nrow(naive_results_rede), "artigos")) +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(caminho_resultado("rede_categorizada.png"),
       plot = p_rede_cat, width = 16, height = 14, dpi = 300)


## ---- 12.4 Heatmap focado em afeto × percepção ---- ##

cat("\n===== HEATMAP AFETO × PERCEPÇÃO =====\n")

# Selecionar top N de cada categoria
top_afeto  <- term_strengths %>% filter(categoria == "Afeto")     %>% head(20) %>% pull(term)
top_percep <- term_strengths %>% filter(categoria == "Percepção") %>% head(20) %>% pull(term)

termos_heat <- unique(c(top_afeto, top_percep))
termos_heat <- intersect(termos_heat, igraph::V(g)$name)

adj_mat <- igraph::as_adjacency_matrix(g, sparse = FALSE, attr = "weight")
adj_sub <- adj_mat[termos_heat, termos_heat]
diag(adj_sub) <- 0

melted <- as.data.frame(adj_sub) %>%
  tibble::rownames_to_column(var = "termo1") %>%
  tidyr::pivot_longer(cols = -termo1, names_to = "termo2", values_to = "peso")

valores_off <- melted$peso[melted$termo1 != melted$termo2]

p_heat <- ggplot(melted, aes(x = termo1, y = termo2, fill = peso)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_gradient(low = "#ffffff", high = "#d62728",
                      trans = "sqrt",
                      limits = c(0, quantile(valores_off, 0.95)),
                      oob = scales::squish, name = "Coocorrência") +
  labs(title = "Heatmap afeto × percepção",
       subtitle = "Intensidade = nº de artigos que contêm ambos os termos",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
    axis.text.y = element_text(size = 7),
    panel.grid = element_blank()
  )

ggsave(caminho_resultado("heatmap_afeto_percepcao.png"),
       plot = p_heat, width = 12, height = 10, dpi = 300)


## ---- 12.5 Grafo bipartido afeto ↔ percepção ---- ##

cat("\n===== GRAFO BIPARTIDO AFETO ↔ PERCEPÇÃO =====\n")

# --- 1. Top N de cada lado ---
n_lado <- 15

lado_afeto <- term_strengths %>%
  filter(categoria == "Afeto") %>%
  head(n_lado) %>%
  pull(term)

lado_percep <- term_strengths %>%
  filter(categoria == "Percepção") %>%
  head(n_lado) %>%
  pull(term)

lado_afeto  <- intersect(lado_afeto,  igraph::V(g)$name)
lado_percep <- intersect(lado_percep, igraph::V(g)$name)

cat("Termos de afeto no grafo:    ", length(lado_afeto), "\n")
cat("Termos de percepção no grafo:", length(lado_percep), "\n")

if (length(lado_afeto) == 0 || length(lado_percep) == 0) {
  cat("⚠️  Faltam termos de afeto ou percepção na rede. Gráfico não gerado.\n")
} else {
  
  # --- 2. Subgrafo com esses termos ---
  g_bip <- igraph::induced_subgraph(g, vids = c(lado_afeto, lado_percep))
  
  # --- 3. Manter só arestas entre os dois lados ---
  arestas_bip <- igraph::as_data_frame(g_bip, what = "edges")
  
  arestas_bip <- arestas_bip %>%
    filter(
      (from %in% lado_afeto  & to %in% lado_percep) |
        (from %in% lado_percep & to %in% lado_afeto)
    )
  
  cat("Pares afeto ↔ percepção:", nrow(arestas_bip), "\n")
  
  if (nrow(arestas_bip) == 0) {
    cat("⚠️  Nenhuma aresta direta entre afeto e percepção. Gráfico não gerado.\n")
  } else {
    
    # --- 4. Construir grafo bipartido com atributo 'type' ---
    g_bip2 <- igraph::graph_from_data_frame(
      arestas_bip,
      directed = FALSE,
      vertices = data.frame(
        name = c(lado_afeto, lado_percep),
        lado = c(rep("Afeto", length(lado_afeto)),
                 rep("Percepção", length(lado_percep))),
        stringsAsFactors = FALSE
      )
    )
    
    # <<< ESSENCIAL: atributo 'type' que o ggraph entende
    V(g_bip2)$type <- V(g_bip2)$lado == "Percepção"
    
    # --- 5. Plotar ---
    set.seed(42)
    
    p_bip <- ggraph(g_bip2, layout = "bipartite") +
      geom_edge_link(aes(width = weight, alpha = weight),
                     color = "gray60", show.legend = FALSE) +
      scale_edge_width(range = c(0.3, 2)) +
      geom_node_point(aes(color = lado), size = 5) +
      geom_node_text(aes(label = name),
                     repel = TRUE, size = 3.5,
                     bg.color = "white", bg.r = 0.15) +
      scale_color_manual(values = c("Afeto" = "#d62728",
                                    "Percepção" = "#1f77b4")) +
      labs(title = "Conexões diretas entre afeto e percepção",
           subtitle = paste(nrow(arestas_bip), "pares conectados"),
           color = "Categoria") +
      theme_void(base_size = 12)
    
    # --- 6. Salvar ---
    ggsave(caminho_resultado("grafo_bipartido_afeto_percepcao.png"),
           plot = p_bip, width = 14, height = 10, dpi = 300)
    cat("OK grafo_bipartido_afeto_percepcao.png\n")
  }
}



## ---- 12.6 Rede de comunidades (opcional) ---- ##

cat("\n===== REDE DE COMUNIDADES =====\n")

comunidades <- igraph::cluster_louvain(g)
V(g)$comunidade <- as.factor(comunidades$membership)

top_terms_80 <- term_strengths %>% head(80) %>% pull(term)
g_com <- igraph::induced_subgraph(g, vids = top_terms_80)

com_sub <- igraph::cluster_louvain(g_com)
V(g_com)$comunidade <- as.factor(com_sub$membership)

set.seed(42)
p_rede_com <- ggraph(g_com, layout = "fr") +
  geom_edge_link(alpha = 0.15, color = "gray70") +
  geom_node_point(aes(color = comunidade), size = 4) +
  geom_node_text(aes(label = name), repel = TRUE, size = 2.8,
                 bg.color = "white", bg.r = 0.15) +
  scale_color_brewer(palette = "Set2") +
  labs(title = "Comunidades temáticas na rede",
       subtitle = paste(length(unique(V(g_com)$comunidade)), "comunidades"),
       color = "Comunidade") +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(caminho_resultado("rede_comunidades.png"),
       plot = p_rede_com, width = 16, height = 14, dpi = 300)
cat("OK rede_comunidades.png\n")


## ---- 12.7 Rede interativa (visNetwork) ---- ##

# install.packages("visNetwork")
library(visNetwork)

cat("\n===== REDE INTERATIVA =====\n")

nodes_df <- data.frame(
  id    = V(g_top)$name,
  label = V(g_top)$name,
  value = igraph::strength(g_top)[V(g_top)$name],
  group = V(g_top)$categoria,
  title = paste0("<b>", V(g_top)$name, "</b><br>",
                 "Categoria: ", V(g_top)$categoria, "<br>",
                 "Força: ", round(igraph::strength(g_top)[V(g_top)$name], 1)),
  stringsAsFactors = FALSE
)

edges_df <- igraph::as_data_frame(g_top, what = "edges")
colnames(edges_df)[1:2] <- c("from", "to")
edges_df$value <- edges_df$weight

vis <- visNetwork(nodes_df, edges_df,
                  main = "Rede de termos categorizada (interativa)",
                  width = "100%", height = "800px") %>%
  visIgraphLayout(layout = "layout_with_fr") %>%
  visNodes(shape = "dot", font = list(size = 14)) %>%
  visEdges(smooth = FALSE, color = list(opacity = 0.3)) %>%
  visGroups(groupname = "Afeto",
            color = list(background = "#d62728", border = "#8b1a1a")) %>%
  visGroups(groupname = "Percepção",
            color = list(background = "#1f77b4", border = "#0d4a75")) %>%
  visGroups(groupname = "Espaço urbano/natureza",
            color = list(background = "#2ca02c", border = "#1a5e1a")) %>%
  visGroups(groupname = "Humano/social",
            color = list(background = "#ff7f0e", border = "#a04d00")) %>%
  visGroups(groupname = "Outro",
            color = list(background = "gray60", border = "gray30")) %>%
  visOptions(highlightNearest = TRUE,
             nodesIdSelection = TRUE) %>%
  visPhysics(stabilization = TRUE) %>%
  visInteraction(navigationButtons = TRUE) %>%
  visLegend(useGroups = TRUE, position = "right")

visSave(vis, file = caminho_resultado("rede_interativa.html"))
cat("OK rede_interativa.html\n")


#### ============================================= ####
#### 13. RELATÓRIO FINAL CONSOLIDADO               ####
#### ============================================= ####

cat("\n\n")
cat("=============================================================\n")
cat("                  RELATÓRIO FINAL                           \n")
cat("=============================================================\n\n")

cat("### AMOSTRA ###\n")
cat("  Total após deduplicação:", nrow(naive_results), "\n")
cat("  Total usado na rede:   ", nrow(naive_results_rede), "\n")
cat("  Termos extraídos:      ", length(terms_full), "\n")
cat("  Nós na rede:           ", length(igraph::V(g)), "\n")
cat("  Arestas na rede:       ", length(igraph::E(g)), "\n\n")

cat("### DISTRIBUIÇÃO POR CATEGORIA ###\n")
print(table(term_strengths$categoria))
cat("\n")

cat("### TOP 20 TERMOS GERAIS ###\n")
print(head(term_strengths[, c("rank", "term", "strength", "categoria")], 20),
      row.names = FALSE)
cat("\n")

cat("### TOP 10 — AFETO ###\n")
print(head(term_strengths %>% filter(categoria == "Afeto") %>%
             select(rank, term, strength), 10),
      row.names = FALSE)
cat("\n")

cat("### TOP 10 — PERCEPÇÃO ###\n")
print(head(term_strengths %>% filter(categoria == "Percepção") %>%
             select(rank, term, strength), 10),
      row.names = FALSE)
cat("\n")

cat("### TERMOS PONTE (conectam afeto e percepção) ###\n")
if (exists("pontes_score_df")) {
  print(head(pontes_score_df %>% select(termo, n_afeto, n_percepcao, score_ponte), 10),
        row.names = FALSE)
} else {
  cat("  (pontes_score_df não disponível — Seção 9H não rodou)\n")
}
cat("\n")

cat("### PARES AFETO ↔ PERCEPÇÃO MAIS FORTES ###\n")
if (exists("pontes") && nrow(pontes) > 0) {
  print(head(pontes, 10), row.names = FALSE)
} else {
  cat("  Nenhuma aresta direta encontrada entre afeto e percepção.\n")
}
cat("\n")

cat("### CUTOFF (80% cumulativo) ###\n")
cat("  Valor do cutoff: ", round(cutoff_cumul, 2), "\n")
cat("  Termos mantidos:", length(kept_terms), "\n\n")

cat("### SOBREPOSIÇÃO WOS × SCOPUS ###\n")
cat("  Só WOS:      ", length(only_wos), "\n")
cat("  Só Scopus:   ", length(only_sco), "\n")
cat("  Em ambas:    ", length(both), "\n\n")

cat("=============================================================\n")
cat("               ARQUIVOS GERADOS                             \n")
cat("=============================================================\n\n")

arquivos_salvos <- list.files(pasta_resultados,
                              pattern = "\\.(csv|png|txt|html|rds)$",
                              full.names = FALSE)

for (f in arquivos_salvos) {
  caminho_f <- file.path(pasta_resultados, f)
  cat(sprintf("  %-50s %8.1f KB\n", f, file.size(caminho_f) / 1024))
}

cat("\n=============================================================\n")
cat("Pasta de resultados:\n  ", pasta_resultados, "\n")
cat("=============================================================\n\n")

# Salvar ambiente completo para retomada
save.image(file = caminho_resultado("ambiente_completo.RData"))
cat("OK Ambiente salvo em ambiente_completo.RData\n")
cat("   (para retomar depois: load('Resultados/ambiente_completo.RData'))\n\n")

cat("✅ SCRIPT CONCLUÍDO COM SUCESSO.\n")





