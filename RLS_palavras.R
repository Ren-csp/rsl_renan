#### Autor: Renan ####
#data: 11/08/2026
# definindo palavras-chave




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
#### 6C. TOP 10 PAÍSES MAIS PRODUTIVOS             ####
#### ============================================= ####

cat("\n===== TOP 10 PAÍSES MAIS PRODUTIVOS =====\n")

# Extração VETORIZADA 
naive_results$pais <- extrair_pais_vetor(naive_results$country)

# Diagnóstico
n_pais_ok <- sum(!is.na(naive_results$pais))
n_pais_na <- sum(is.na(naive_results$pais))
cat("Países identificados:", n_pais_ok, "de", nrow(naive_results), "\n")
cat("Não identificados:   ", n_pais_na, "\n\n")

# Amostra de países que não foram reconhecidos (para debug)
if (n_pais_na > 0) {
  cat("Exemplos de afiliações NÃO reconhecidas:\n")
  exemplos_na <- head(naive_results$country[is.na(naive_results$pais)], 5)
  for (e in exemplos_na) cat("  -", substr(e, 1, 120), "\n")
  cat("\n")
}

# Top 10 países
top_paises <- as.data.frame(
  sort(table(naive_results$pais, useNA = "no"), decreasing = TRUE)
)
colnames(top_paises) <- c("pais", "n_artigos")
top_paises <- head(top_paises, 10)
print(top_paises, row.names = FALSE)


#### ============================================= ####
#### 6D. GRÁFICO NORTE GLOBAL × SUL GLOBAL         ####
#### ============================================= ####

cat("\n===== GRÁFICO NORTE × SUL GLOBAL =====\n")

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

cat("\n--- Contagem por região ---\n")
print(regiao_tab, row.names = FALSE)

# Top 10 países coloridos por região
top_paises_plot <- as.data.frame(sort(table(naive_results$pais, useNA = "no"),
                                      decreasing = TRUE))
colnames(top_paises_plot) <- c("pais", "n_artigos")
top_paises_plot <- head(top_paises_plot, 10)
top_paises_plot$regiao <- ifelse(top_paises_plot$pais %in% paises_norte,
                                 "Norte Global", "Sul Global")

p_norte_sul <- ggplot(top_paises_plot,
                      aes(x = reorder(pais, n_artigos),
                          y = n_artigos,
                          fill = regiao)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("Norte Global" = "#1f77b4",
                               "Sul Global"   = "#d62728")) +
  labs(title = "Top 10 países produtores: Norte Global × Sul Global",
       x = NULL, y = "Número de artigos", fill = "Região") +
  theme_minimal(base_size = 13)

ggsave(caminho_resultado("top10_paises_norte_sul.png"),
       plot = p_norte_sul, width = 10, height = 7, dpi = 300)
cat("OK Resultados/top10_paises_norte_sul.png\n")

# Gráfico agregado por região
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
cat("OK Resultados/producao_norte_sul.png\n")



#### ============================================= ####
#### 6E. NORMALIZAÇÃO SINGULAR/PLURAL              ####
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

# --- Aplicar nas 3 colunas de texto ---
naive_results$title_norm    <- normalizar_plural(naive_results$title)
naive_results$abstract_norm <- normalizar_plural(naive_results$abstract)
naive_results$keywords_norm <- normalizar_plural(naive_results$keywords)

# --- Diagnóstico ---
cat("Colunas criadas em naive_results:\n")
cat("  title_norm:   ", length(naive_results$title_norm), "valores\n")
cat("  abstract_norm:", length(naive_results$abstract_norm), "valores\n")
cat("  keywords_norm:", length(naive_results$keywords_norm), "valores\n")

cat("\nExemplos (title):\n")
idx <- which(grepl("\\bspaces\\b|\\bparks\\b", naive_results$title, ignore.case = TRUE))[1:3]
for (i in idx) {
  if (!is.na(i)) {
    cat("  ANTES: ", naive_results$title[i], "\n")
    cat("  DEPOIS:", naive_results$title_norm[i], "\n\n")
  }
}

cat("OK Colunas *_norm criadas.\n")


#### ============================================= ####
#### 7. EXTRAÇÃO DE TERMOS (com abstracts)         ####
#### ============================================= ####

cat("\n===== EXTRAINDO TERMOS =====\n")

## ---- 7.0 Função de limpeza de texto ---- ##
limpar_texto <- function(x) {
  x <- as.character(x)
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub('^[\\s"\\{\\}]+', "", x)
  x <- gsub('[\\s"\\{\\}]+$', "", x)
  x <- gsub('"', "", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

## ---- 7.1 Limpar colunas críticas (VERSÕES NORMALIZADAS) ---- ##
cat("Limpando textos (versões normalizadas)...\n")

naive_results$title_norm    <- limpar_texto(naive_results$title_norm)
naive_results$abstract_norm <- limpar_texto(naive_results$abstract_norm)
naive_results$keywords_norm <- limpar_texto(naive_results$keywords_norm)

# Garantir que NÃO há NA
naive_results$title_norm[is.na(naive_results$title_norm)]       <- ""
naive_results$abstract_norm[is.na(naive_results$abstract_norm)] <- ""
naive_results$keywords_norm[is.na(naive_results$keywords_norm)] <- ""

cat("Base limpa:", nrow(naive_results), "artigos\n")
cat("Exemplos de keywords normalizadas:\n")
print(head(naive_results$keywords_norm[naive_results$keywords_norm != ""], 3))


## ---- 7.2 Extrair keywords (tagged) ---- ##
cat("\n--- [1/3] Extraindo keywords ---\n")
t0 <- Sys.time()
keywords <- litsearchr::extract_terms(
  keywords = naive_results[, "keywords_norm"],
  min_freq = 2,
  method = "tagged"
)
cat("Keywords:", length(keywords), "| tempo:",
    round(difftime(Sys.time(), t0, units = "secs")), "s\n")


## ---- 7.3 Extrair title terms (fakerake) ---- ##
cat("\n--- [2/3] Extraindo title terms ---\n")
t0 <- Sys.time()
title_terms <- litsearchr::extract_terms(
  text = naive_results[, "title_norm"],
  method = "fakerake",
  min_freq = 2,
  min_n = 1,
  max_n = 4
)
cat("Title terms:", length(title_terms), "| tempo:",
    round(difftime(Sys.time(), t0, units = "secs")), "s\n")

## ---- 7.4 Extrair abstract terms (fakerake) ---- ##
cat("\n--- [3/3] Extraindo abstract terms ---\n")
cat("⚠️  Esta etapa pode levar 20-40 minutos. Aguarde...\n")

saveRDS(
  list(keywords = keywords, title_terms = title_terms),
  file = caminho_resultado("checkpoint_termos_parcial.rds")
)
cat("Checkpoint parcial salvo (keywords + title_terms).\n")

abstracts_ok <- naive_results$abstract_norm
abstracts_ok[nchar(abstracts_ok) < 200]  <- ""
abstracts_ok[nchar(abstracts_ok) > 3000] <-
  substr(abstracts_ok[nchar(abstracts_ok) > 3000], 1, 3000)

n_abstracts_usados <- sum(abstracts_ok != "")
cat("Abstracts usados:", n_abstracts_usados, "de", nrow(naive_results), "\n")

t0 <- Sys.time()
abstract_terms <- litsearchr::extract_terms(
  text = abstracts_ok,
  method = "fakerake",
  min_freq = 3,
  min_n = 1,
  max_n = 3
)
tempo_abs <- round(difftime(Sys.time(), t0, units = "mins"), 1)
cat("Abstract terms:", length(abstract_terms),
    "| tempo:", tempo_abs, "min\n")

saveRDS(
  list(keywords = keywords,
       title_terms = title_terms,
       abstract_terms = abstract_terms),
  file = caminho_resultado("checkpoint_termos_completo.rds")
)
cat("Checkpoint completo salvo.\n")

## ---- 7.5 Combinar termos ---- ##
terms_min  <- unique(c(keywords, title_terms))
terms_full <- unique(c(keywords, title_terms, abstract_terms))

# Limpeza final
terms_min  <- limpar_texto(terms_min)
terms_full <- limpar_texto(terms_full)

terms_min  <- unique(terms_min[terms_min != ""])
terms_full <- unique(terms_full[terms_full != ""])

## ---- 7.6 Sanity checks ---- ##
if (length(terms_min) < 2) {
  stop("ERRO: menos de 2 termos em 'terms_min'.")
}
if (length(terms_full) < 2) {
  stop("ERRO: menos de 2 termos em 'terms_full'.")
}

## ---- 7.7 Relatório final ---- ##
cat("\n===== RESUMO DA EXTRAÇÃO =====\n")
cat("Keywords:      ", length(keywords), "\n")
cat("Title terms:   ", length(title_terms), "\n")
cat("Abstract terms:", length(abstract_terms), "\n")
cat("terms_min:     ", length(terms_min), "\n")
cat("terms_full:    ", length(terms_full), "\n")

cat("\nPrimeiros 10 termos de terms_min (devem estar limpos):\n")
print(head(terms_min, 10))

#### ============================================= ####
#### 7.8 CHECAGEM EXPLÍCITA DOS TERMOS DE INTERESSE ####
#### ============================================= ####

cat("\n===== TERMOS DE INTERESSE NA AMOSTRA =====\n")

termos_interesse <- c(
  "affection", "affective", "affect",
  "emotion", "emotional", "feeling", "mood",
  "perception", "perceived", "perceptual",
  "public perception", "environmental perception",
  "place attachment", "place identity",
  "nature relatedness", "connectedness to nature",
  "human-nature", "nature contact",
  "well-being", "wellbeing", "mental health",
  "urban park", "urban green space", "open space", "public space"
)

checagem <- data.frame(
  termo      = termos_interesse,
  n_keywords = NA_integer_,
  n_title    = NA_integer_,
  n_abstract = NA_integer_,
  n_total    = NA_integer_
)

for (i in seq_along(termos_interesse)) {
  t <- termos_interesse[i]
  pat <- paste0("\\b", gsub(" ", "\\\\s+", t), "s?\\b")
  
  checagem$n_keywords[i] <- sum(grepl(pat, naive_results$keywords, ignore.case = TRUE), na.rm = TRUE)
  checagem$n_title[i]    <- sum(grepl(pat, naive_results$title,    ignore.case = TRUE), na.rm = TRUE)
  checagem$n_abstract[i] <- sum(grepl(pat, naive_results$abstract, ignore.case = TRUE), na.rm = TRUE)
  checagem$n_total[i]    <- sum(
    grepl(pat, naive_results$keywords, ignore.case = TRUE) |
      grepl(pat, naive_results$title,    ignore.case = TRUE) |
      grepl(pat, naive_results$abstract, ignore.case = TRUE),
    na.rm = TRUE
  )
}

checagem <- checagem %>% arrange(desc(n_total))
print(checagem, row.names = FALSE)

write.csv(checagem,
          caminho_resultado("checagem_termos_interesse.csv"),
          row.names = FALSE)
cat("OK Resultados/checagem_termos_interesse.csv\n")



#### ============================================= ####
#### 8. REDE DE TERMOS                             ####
#### ============================================= ####

cat("\n===== CONSTRUINDO REDE DE TERMOS =====\n")
cat("Artigos disponíveis:", nrow(naive_results), "\n")

if (nrow(naive_results) > 5000) {
  set.seed(42)
  naive_results_rede <- naive_results %>% sample_n(5000)
  cat("Amostra aplicada: 5000 artigos\n")
} else {
  naive_results_rede <- naive_results
  cat("Usando todos os artigos\n")
}

# Re-extrair termos na amostra (VERSÕES NORMALIZADAS)
cat("=== Extraindo keywords_r ===\n")
keywords_r <- litsearchr::extract_terms(
  keywords = naive_results_rede[, "keywords_norm"],
  min_freq = 3,
  method = "tagged"
)
cat("keywords_r:", length(keywords_r), "\n")

cat("=== Extraindo title_terms_r ===\n")
title_terms_r <- litsearchr::extract_terms(
  text = naive_results_rede[, "title_norm"],
  method = "fakerake",
  min_freq = 3,
  min_n = 1
)
cat("title_terms_r:", length(title_terms_r), "\n")

terms_min_r <- unique(c(keywords_r, title_terms_r))
cat("terms_min_r:", length(terms_min_r), "\n")

cat("=== Criando DFM ===\n")
docs <- paste(naive_results_rede$title_norm,
              naive_results_rede$abstract_norm,
              sep = " ")
dfm  <- litsearchr::create_dfm(elements = docs, features = terms_min_r)
cat("DFM criado:", nrow(dfm), "x", ncol(dfm), "\n")

cat("=== Criando rede ===\n")
g <- litsearchr::create_network(dfm, min_studies = 3)
cat("Nós:", length(igraph::V(g)), "\n")
cat("Arestas:", length(igraph::E(g)), "\n")


#### ============================================= ####
#### 9. FORÇA DOS TERMOS                           ####
#### ============================================= ####

salt_marsh_strengths_raw <- igraph::strength(g)

salt_marsh_strengths <- data.frame(
  term = names(salt_marsh_strengths_raw),
  strength = salt_marsh_strengths_raw,
  row.names = NULL
)

term_strengths <- salt_marsh_strengths %>%
  mutate(rank = rank(-strength, ties.method = "min")) %>%
  arrange(desc(strength))

cat("\n===== TOP 20 TERMOS =====\n")
print(head(term_strengths, 20))



##   9B. DISTÂNCIA DE TERMOS-CHAVE NA REDE       ##


cat("\n===== DISTÂNCIA DE TERMOS-CHAVE =====\n")

termos_alvo <- c(
  # Afeto / emoção
  "affection", "affective", "affect",
  "emotion", "emotional",
  "feeling", "mood",
  # Percepção
  "perception", "perceived", "perceptual",
  "public perception", "environmental perception",
  # Relação humano-natureza
  "place attachment", "place identity",
  "nature relatedness", "connectedness to nature",
  "human-nature", "nature contact",
  # Bem-estar / saúde mental
  "well-being", "wellbeing", "mental health",
  # Espaços urbanos (contexto)
  "urban park", "urban green space", "open space", "public space"
)

# Verificar quais existem na rede
termos_presentes <- termos_alvo[termos_alvo %in% igraph::V(g)$name]
termos_ausentes  <- setdiff(termos_alvo, termos_presentes)

cat("Termos encontrados na rede:", length(termos_presentes), "\n")
print(termos_presentes)
cat("\nTermos NÃO encontrados na rede:", length(termos_ausentes), "\n")
print(termos_ausentes)

if (length(termos_presentes) == 0) {
  stop("Nenhum termo-alvo está na rede. Verifique a grafia ou extraia esses termos.")
}

## ---- Matriz de distâncias (caminho mais curto) ---- ##
dist_mat <- igraph::distances(g, v = termos_presentes, to = igraph::V(g)$name)

dist_df <- as.data.frame(dist_mat) %>%
  tibble::rownames_to_column(var = "termo_alvo") %>%
  tidyr::pivot_longer(
    cols = -termo_alvo,
    names_to = "termo_vizinho",
    values_to = "distancia"
  ) %>%
  filter(
    !is.infinite(distancia),
    termo_alvo != termo_vizinho
  )

## ---- Top 15 termos mais próximos de cada alvo ---- ##
cat("\n--- Top 15 termos mais próximos de cada alvo ---\n")

top_proximos <- dist_df %>%
  group_by(termo_alvo) %>%
  arrange(distancia) %>%
  slice_head(n = 15) %>%
  ungroup()

for (alvo in termos_presentes) {
  cat("\n>>>", toupper(alvo), "<<<\n")
  sub <- top_proximos %>% filter(termo_alvo == alvo)
  for (i in seq_len(nrow(sub))) {
    cat(sprintf("  %2d. %-35s (distância = %d)\n",
                i, sub$termo_vizinho[i], sub$distancia[i]))
  }
}

## ---- Salvar CSV ---- ##
write.csv(dist_df,
          caminho_resultado("distancias_termos_alvo.csv"),
          row.names = FALSE)
cat("\nOK Resultados/distancias_termos_alvo.csv\n")

write.csv(top_proximos,
          caminho_resultado("top15_proximos_termos_alvo.csv"),
          row.names = FALSE)
cat("OK Resultados/top15_proximos_termos_alvo.csv\n")



## 9C. SIMILARIDADE SEMÂNTICA (via DFM)       ##

cat("\n===== SIMILARIDADE SEMÂNTICA (cosseno) =====\n")

termos_dfm <- termos_alvo[termos_alvo %in% colnames(dfm)]
cat("Termos-alvo no DFM:", length(termos_dfm), "\n")
print(termos_dfm)

if (length(termos_dfm) == 0) {
  cat("⚠️ Nenhum termo-alvo está no DFM. Pulando análise.\n")
} else {
  
  cat("Calculando matriz de similaridade...\n")
  
  dfm_norm <- scale(dfm, center = FALSE,
                    scale = sqrt(colSums(dfm^2)))
  dfm_norm[is.na(dfm_norm)] <- 0
  
  sim_mat <- crossprod(dfm_norm)
  
  cat("\n--- Top 15 termos mais similares (cosseno) ---\n")
  
  similares_lista <- list()
  
  for (alvo in termos_dfm) {
    sims <- sim_mat[alvo, ]
    sims <- sims[names(sims) != alvo]
    sims <- sort(sims, decreasing = TRUE)
    top15 <- head(sims, 15)
    
    cat("\n>>>", toupper(alvo), "<<<\n")
    for (i in seq_along(top15)) {
      cat(sprintf("  %2d. %-35s (similaridade = %.3f)\n",
                  i, names(top15)[i], top15[i]))
    }
    
    similares_lista[[alvo]] <- data.frame(
      termo_alvo    = alvo,
      termo_similar = names(top15),
      similaridade  = as.numeric(top15),
      rank          = seq_along(top15)
    )
  }
  
  similares_df <- do.call(rbind, similares_lista)
  write.csv(similares_df,
            caminho_resultado("similaridade_termos_alvo.csv"),
            row.names = FALSE)
  cat("\nOK Resultados/similaridade_termos_alvo.csv\n")
}



## 9D. SUBGRAFO FOCAL (vizinhança)               ##

cat("\n===== SUBGRAFO FOCAL =====\n")

alvo_principal <- "affection"

if (!alvo_principal %in% igraph::V(g)$name) {
  cat("⚠️ Termo", alvo_principal, "não está na rede. Tentando alternativas...\n")
  alternativas <- termos_alvo[termos_alvo %in% igraph::V(g)$name]
  if (length(alternativas) == 0) {
    stop("Nenhum termo-alvo presente na rede.")
  }
  alvo_principal <- alternativas[1]
  cat("Usando:", alvo_principal, "\n")
}

vizinhos <- igraph::ego(g, order = 2, nodes = alvo_principal)[[1]]
nomes_vizinhos <- igraph::V(g)$name[vizinhos]

cat("Vizinhos de", alvo_principal, "em 2 saltos:", length(nomes_vizinhos), "\n")

g_focal <- igraph::induced_subgraph(g, vids = nomes_vizinhos)

set.seed(42)
p_focal <- ggraph(g_focal, layout = "fr") +
  geom_edge_link(aes(alpha = weight, width = weight),
                 color = "gray60", show.legend = FALSE) +
  scale_edge_width(range = c(0.3, 1.5)) +
  geom_node_point(
    aes(size = igraph::strength(g_focal),
        color = name == alvo_principal),
    show.legend = FALSE
  ) +
  scale_size(range = c(2, 8)) +
  scale_color_manual(values = c("TRUE" = "#d62728", "FALSE" = "#1f77b4")) +
  geom_node_text(
    aes(label = name,
        fontface = ifelse(name == alvo_principal, "bold", "plain")),
    repel = TRUE,
    size = 3.5,
    bg.color = "white", bg.r = 0.15,
    max.overlaps = 30
  ) +
  labs(
    title = paste("Vizinhança de", toupper(alvo_principal), "na rede"),
    subtitle = paste(length(nomes_vizinhos), "termos em até 2 saltos")
  ) +
  theme_void(base_size = 12)

ggsave(caminho_resultado(paste0("subgrafo_", alvo_principal, ".png")),
       plot = p_focal, width = 14, height = 12, dpi = 300)
cat("OK Resultados/subgrafo_", alvo_principal, ".png\n", sep = "")



## 9E. GRÁFICO: TOP 20 MAIS PRÓXIMOS             ##

cat("\n===== GRÁFICO: TOP 20 MAIS PRÓXIMOS =====\n")

top20 <- dist_df %>%
  filter(termo_alvo == alvo_principal) %>%
  arrange(distancia) %>%
  slice_head(n = 20)

p_barras <- ggplot(top20,
                   aes(x = reorder(termo_vizinho, -distancia),
                       y = distancia)) +
  geom_col(fill = "#1f77b4") +
  geom_text(aes(label = distancia),
            hjust = -0.3, size = 3.5) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = paste("Top 20 termos mais próximos de",
                  toupper(alvo_principal)),
    subtitle = "Distância de caminho mínimo na rede de coocorrência (menor = mais próximo)",
    x = NULL,
    y = "Distância na rede"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )

ggsave(caminho_resultado(paste0("top20_proximos_", alvo_principal, ".png")),
       plot = p_barras, width = 10, height = 9, dpi = 300)
cat("OK Resultados/top20_proximos_", alvo_principal, ".png\n", sep = "")



#### ============================================= ####
#### 9F. TERMOS CANDIDATOS À EXPANSÃO              ####
#### ============================================= ####

cat("\n===== TERMOS CANDIDATOS À EXPANSÃO =====\n")

# 1. Termos raros (min_freq baixo) que ficaram de fora
termos_raros <- litsearchr::extract_terms(
  text = naive_results$abstract_norm,
  method = "fakerake",
  min_freq = 2,
  min_n = 1,
  max_n = 3
)

candidatos_raros <- setdiff(termos_raros, terms_full)
cat("Termos raros (fora do terms_full):", length(candidatos_raros), "\n")

# 2. Vizinhos diretos (1 salto) dos termos-alvo na rede
alvos_presentes <- intersect(termos_alvo, igraph::V(g)$name)

vizinhos_diretos <- unique(unlist(lapply(alvos_presentes, function(a) {
  igraph::neighbors(g, a)$name
})))
cat("Vizinhos diretos dos alvos:", length(vizinhos_diretos), "\n")

# 3. Termos que já estão na string original
termos_ja_usados <- c(
  # Afeto
  "affection", "emotion", "emotional", "feeling", "affective",
  # Relação humano-natureza
  "human-nature relationship", "human-nature interaction",
  "place attachment", "place identity",
  # Espaços urbanos
  "urban green area", "urban park", "urban open space",
  "urban environment", "open space",
  # Percepção
  "environmental perception", "perception",
  "environmental psychology",
  # Bônus
  "people in nature", "nature contact"
)

# 4. Combinar candidatos
candidatos_novos <- setdiff(
  unique(c(candidatos_raros, vizinhos_diretos)),
  termos_ja_usados
)

cat("Candidatos novos (não usados na busca):", length(candidatos_novos), "\n")

# 5. Salvar para revisão manual
candidatos_df <- data.frame(
  termo = candidatos_novos,
  stringsAsFactors = FALSE
)
write.csv(candidatos_df,
          caminho_resultado("termos_candidatos_expansao.csv"),
          row.names = FALSE)
cat("OK Resultados/termos_candidatos_expansao.csv\n")

cat("\nPrimeiros 30 candidatos:\n")
print(head(candidatos_df$termo, 30))


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
#### 11. COMPARAÇÃO WOS × SCOPUS                   ####
#### ============================================= ####

cat("\n===== SOBREPOSIÇÃO WOS x SCOPUS =====\n")

titulos_wos <- tolower(trimws(dados_WOS$title))
titulos_sco <- tolower(trimws(dados_SCO$title))

only_wos <- setdiff(titulos_wos, titulos_sco)
only_sco <- setdiff(titulos_sco, titulos_wos)
both     <- intersect(titulos_wos, titulos_sco)

cat("Exclusivos WOS:   ", length(only_wos), "\n")
cat("Exclusivos Scopus:", length(only_sco), "\n")
cat("Em ambas as bases:", length(both), "\n")


#### ============================================= ####
#### 12. EXPORTAR RESULTADOS (pasta Resultados)   ####
#### ============================================= ####

cat("\n===== EXPORTANDO PARA:", pasta_resultados, "=====\n")

## ---- 12.1 CSVs ---- ##
write.csv(term_strengths,
          caminho_resultado("termos_forca.csv"), row.names = FALSE)
cat("OK termos_forca.csv\n")

write.csv(data.frame(termo = kept_terms),
          caminho_resultado("termos_finais.csv"), row.names = FALSE)
cat("OK termos_finais.csv\n")

write.csv(naive_results,
          caminho_resultado("estudos_deduplicados.csv"), row.names = FALSE)
cat("OK estudos_deduplicados.csv\n")

write.csv(top_autores,
          caminho_resultado("top10_autores.csv"), row.names = FALSE)
cat("OK top10_autores.csv\n")

write.csv(top_paises,
          caminho_resultado("top10_paises.csv"), row.names = FALSE)
cat("OK top10_paises.csv\n")

write.csv(regiao_tab,
          caminho_resultado("producao_por_regiao.csv"), row.names = FALSE)
cat("OK producao_por_regiao.csv\n")

dados_sobreposicao <- data.frame(
  categoria = c("Só WOS", "Só Scopus", "Em ambas"),
  n = c(length(only_wos), length(only_sco), length(both))
)
write.csv(dados_sobreposicao,
          caminho_resultado("sobreposicao_bases.csv"), row.names = FALSE)
cat("OK sobreposicao_bases.csv\n")



## 12.2 Gráfico: curva de cutoff (MELHORADO)     ##

library(ggplot2)
library(ggrepel)
library(dplyr)

cat("\n===== GRÁFICO: CURVA DE CUTOFF (melhorado) =====\n")

# 1. Preparar dados: só rotular o top 15
n_rotulos <- 15
term_strengths_plot <- term_strengths %>%
  mutate(
    label = ifelse(rank <= n_rotulos, term, NA_character_),
    abaixo_cutoff = strength < cutoff_cumul
  )

# 2. Nº de termos que passam o cutoff
n_manter <- sum(term_strengths$strength >= cutoff_cumul)
n_total  <- nrow(term_strengths)
pct      <- round(100 * n_manter / n_total, 1)

# 3. Gráfico
p_cutoff <- ggplot(term_strengths_plot,
                   aes(x = rank, y = strength)) +
  
  # Área abaixo do cutoff (vermelho claro)
  geom_rect(aes(xmin = -Inf, xmax = Inf,
                ymin = -Inf, ymax = cutoff_cumul),
            fill = "#ffe5e5", alpha = 0.5, inherit.aes = FALSE) +
  
  # Linha da curva
  geom_line(color = "#1f77b4", linewidth = 0.8) +
  geom_point(color = "#1f77b4", size = 2) +
  
  # Linha do cutoff
  geom_hline(yintercept = cutoff_cumul,
             linetype = "dashed",
             color = "#d62728",
             linewidth = 0.9) +
  
  # Anotação do cutoff
  annotate("label",
           x = max(term_strengths$rank) * 0.75,
           y = cutoff_cumul,
           label = paste0("Cutoff (80% cumulativo) = ",
                          round(cutoff_cumul, 1)),
           color = "#d62728",
           fill = "white",
           label.size = 0.3,
           size = 4) +
  
  # Anotação do nº de termos mantidos
  annotate("text",
           x = max(term_strengths$rank) * 0.75,
           y = cutoff_cumul * 0.6,
           label = paste0(n_manter, " de ", n_total,
                          " termos (", pct, "%) mantidos"),
           color = "#d62728",
           size = 4,
           fontface = "italic") +
  
  # Rótulos repelidos só no top 15
  geom_text_repel(aes(label = label),
                  size = 3.8,
                  color = "black",
                  fontface = "bold",
                  box.padding = 0.4,
                  point.padding = 0.3,
                  segment.color = "gray50",
                  segment.size = 0.3,
                  min.segment.length = 0,
                  max.overlaps = 20,
                  direction = "y",
                  nudge_x = 30,
                  hjust = 0,
                  na.rm = TRUE) +
  
  # Eixos
  scale_x_continuous(limits = c(0, max(term_strengths$rank)),
                     breaks = seq(0, max(term_strengths$rank), by = 50),
                     expand = c(0.02, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.1))) +
  
  # Títulos
  labs(
    title = "Força dos termos e ponto de corte (80% cumulativo)",
    subtitle = paste0("Total de termos: ", n_total,
                      "  |  Mantidos após cutoff: ", n_manter,
                      " (", pct, "%)  |  Artigos analisados: ",
                      nrow(naive_results_rede)),
    x = "Ranking do termo (1 = mais forte)",
    y = "Força (strength)",
    caption = "Termos na área rosa estão abaixo do cutoff e foram descartados."
  ) +
  
  # Tema
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(color = "gray40", size = 11),
    plot.caption = element_text(color = "gray50", size = 9, hjust = 0),
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold"),
    plot.margin = margin(15, 30, 15, 15)
  )

# 4. Salvar
ggsave(caminho_resultado("curva_cutoff.png"),
       plot = p_cutoff, width = 14, height = 8, dpi = 300)
cat("OK Resultados/curva_cutoff.png\n")


## ---- 12.3 Top 30 termos ---- ##
top30 <- term_strengths %>% head(30)

p_top30 <- ggplot(top30, aes(x = reorder(term, strength), y = strength)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Top 30 termos mais fortes",
       x = NULL, y = "Força (strength)") +
  theme_minimal(base_size = 12)

ggsave(caminho_resultado("top30_termos.png"),
       plot = p_top30, width = 10, height = 10, dpi = 300)
cat("OK top30_termos.png\n")

## ---- 12.4 Sobreposição WOS × Scopus ---- ##
p_sobreposicao <- ggplot(dados_sobreposicao, aes(x = categoria, y = n, fill = categoria)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = n), vjust = -0.5, size = 5) +
  labs(title = "Sobreposição entre WOS e Scopus",
       x = NULL, y = "Número de estudos") +
  theme_minimal(base_size = 14)

ggsave(caminho_resultado("sobreposicao.png"),
       plot = p_sobreposicao, width = 8, height = 6, dpi = 300)
cat("OK sobreposicao.png\n")



## 12.5 Gráfico: rede de termos (TOP N)     ##

cat("\n===== GRÁFICO: REDE DE TERMOS (top 50) =====\n")

# 1. Pegar top 50 termos por strength
top_n <- 50
top_terms <- term_strengths %>%
  arrange(desc(strength)) %>%
  slice_head(n = top_n) %>%
  pull(term)

# 2. Criar subgrafo só com esses termos
g_top <- igraph::induced_subgraph(g, vids = top_terms)

# 3. Manter só arestas com peso mínimo (evita linhas demais)
peso_min <- quantile(igraph::E(g_top)$weight, 0.3)  # descarta 30% mais fracas
g_top <- igraph::delete_edges(g_top,
                              igraph::E(g_top)[igraph::E(g_top)$weight < peso_min])

# 4. Plotar
set.seed(42)
p_rede_top <- ggraph(g_top, layout = "fr") +           # Fruchterman-Reingold (bom p/ redes densas)
  geom_edge_link(aes(alpha = weight, width = weight),
                 color = "gray60", show.legend = FALSE) +
  scale_edge_width(range = c(0.2, 1.5)) +
  geom_node_point(size = 3, color = "#1f77b4") +
  geom_node_text(aes(label = name),
                 repel = TRUE,                # <<< evita sobreposição de rótulos
                 size = 3, color = "black",
                 bg.color = "white", bg.r = 0.15) +
  labs(title = paste("Rede de termos — top", top_n, "mais fortes"),
       subtitle = paste(nrow(naive_results_rede), "artigos analisados")) +
  theme_void(base_size = 12)

ggsave(caminho_resultado("rede_top50.png"),
       plot = p_rede_top, width = 14, height = 12, dpi = 300)
cat("OK Resultados/rede_top50.png\n")



## 12.6 Gráfico: rede com comunidades             ##

library(ggraph)
library(igraph)

cat("\n===== REDE COM COMUNIDADES =====\n")

# 1. Detectar comunidades (Louvain)
comunidades <- igraph::cluster_louvain(g)
V(g)$comunidade <- as.factor(comunidades$membership)

# 2. Filtrar para top 80 termos (senão fica poluído)
top_terms_80 <- term_strengths %>%
  arrange(desc(strength)) %>%
  slice_head(n = 80) %>%
  pull(term)

g_com <- igraph::induced_subgraph(g, vids = top_terms_80)

# 3. Re-detectar comunidades no subgrafo
com_sub <- igraph::cluster_louvain(g_com)
V(g_com)$comunidade <- as.factor(com_sub$membership)

# 4. Plotar colorindo por comunidade
set.seed(42)
p_rede_com <- ggraph(g_com, layout = "fr") +
  geom_edge_link(alpha = 0.15, color = "gray70") +
  geom_node_point(aes(color = comunidade), size = 4) +
  geom_node_text(aes(label = name),
                 repel = TRUE,
                 size = 2.8,
                 bg.color = "white", bg.r = 0.15) +
  scale_color_brewer(palette = "Set2") +
  labs(title = "Rede de termos agrupados por comunidade temática",
       subtitle = paste("Top 80 termos |",
                        length(unique(V(g_com)$comunidade)), "comunidades"),
       color = "Comunidade") +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(caminho_resultado("rede_comunidades.png"),
       plot = p_rede_com, width = 16, height = 14, dpi = 300)
cat("OK Resultados/rede_comunidades.png\n")


#### ============================================= ####
#### 12.7 Heatmap de coocorrência (top 30)         ####
#### ============================================= ####

library(tidyr)
library(ggplot2)

cat("\n===== HEATMAP DE COOCORRÊNCIA =====\n")

# 1. Garantir que a rede 'g' existe
if (!exists("g")) {
  stop("ERRO: objeto 'g' (rede) não encontrado. Rode a Seção 8 primeiro.")
}

# 2. Pegar top 30 termos por força
top30_terms <- term_strengths %>%
  arrange(desc(strength)) %>%
  slice_head(n = 30) %>%
  pull(term)

cat("Termos selecionados:", length(top30_terms), "\n")

# 3. Matriz de adjacência PONDERADA pelo nº de estudos em que coocorrem
adj_mat <- igraph::as_adjacency_matrix(
  g,
  sparse = FALSE,
  attr   = "weight"
)
adj_top <- adj_mat[top30_terms, top30_terms]

# <<< ZERA A DIAGONAL (termo contra si mesmo distorce a escala)
diag(adj_top) <- 0

melted <- as.data.frame(adj_top) %>%
  tibble::rownames_to_column(var = "termo1") %>%
  tidyr::pivot_longer(
    cols = -termo1,
    names_to = "termo2",
    values_to = "peso"
  )

# Diagnóstico da distribuição real (fora da diagonal)
valores_off <- melted$peso[melted$termo1 != melted$termo2]
cat("Distribuição dos pesos (fora da diagonal):\n")
print(summary(valores_off))

p_heatmap <- ggplot(melted, aes(x = termo1, y = termo2, fill = peso)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_gradient(
    low = "#ffffff",
    high = "#d62728",
    trans = "sqrt",                                    # <<< ESCALA
    limits = c(0, quantile(valores_off, 0.95)),        # <<< corta extremos
    oob = scales::squish,
    name = "Coocorrência"
  ) +
  labs(
    title = "Heatmap de coocorrência — top 30 termos",
    subtitle = paste("Intensidade = nº de artigos em que os dois termos aparecem juntos"),
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
    axis.text.y = element_text(size = 7),
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "gray40", size = 9)
  )

# 7. Salvar
ggsave(caminho_resultado("heatmap_coocorrencia.png"),
       plot = p_heatmap, width = 12, height = 10, dpi = 300)
cat("OK Resultados/heatmap_coocorrencia.png\n")


## 12.8 Rede interativa (visNetwork)             ##

# install.packages("visNetwork")
library(visNetwork)

cat("\n===== REDE INTERATIVA =====\n")

# Preparar nós
nodes_df <- data.frame(
  id = V(g_top)$name,
  label = V(g_top)$name,
  value = igraph::strength(g_top)[V(g_top)$name],  # tamanho proporcional à força
  title = paste0("<b>", V(g_top)$name, "</b><br>",
                 "Força: ", round(igraph::strength(g_top)[V(g_top)$name], 1)),
  stringsAsFactors = FALSE
)

# Preparar arestas
edges_df <- igraph::as_data_frame(g_top, what = "edges")
colnames(edges_df)[1:2] <- c("from", "to")
edges_df$value <- edges_df$weight

# Gerar HTML interativo
vis <- visNetwork(nodes_df, edges_df,
                  main = "Rede de termos (interativa)",
                  width = "100%", height = "800px") %>%
  visIgraphLayout(layout = "layout_with_fr") %>%
  visNodes(shape = "dot", font = list(size = 14)) %>%
  visEdges(smooth = FALSE, color = list(opacity = 0.3)) %>%
  visOptions(highlightNearest = TRUE,
             nodesIdSelection = TRUE) %>%
  visPhysics(stabilization = TRUE) %>%
  visInteraction(navigationButtons = TRUE)

visSave(vis, file = caminho_resultado("rede_interativa.html"))
cat("OK Resultados/rede_interativa.html\n")
cat("Abra no navegador para explorar.\n")



#### ============================================= ####
#### 13. CONFIRMAÇÃO FINAL                         ####
#### ============================================= ####

cat("\n===== ARQUIVOS EM:", pasta_resultados, "=====\n")

arquivos_salvos <- list.files(pasta_resultados,
                              pattern = "\\.(csv|png|txt)$",
                              full.names = FALSE)
print(arquivos_salvos)

cat("\n===== TAMANHO DOS ARQUIVOS =====\n")
for (f in arquivos_salvos) {
  caminho_f <- file.path(pasta_resultados, f)
  cat(sprintf("  %-40s %8.1f KB\n", f, file.size(caminho_f) / 1024))
}

cat("\n===== SCRIPT CONCLUÍDO =====\n")
cat("Todos os resultados foram salvos em:\n  ", pasta_resultados, "\n\n")

cat("Objetos criados:\n")
for (o in c("dados_WOS", "dados_SCO", "naive_results_import", "naive_results",
            "keywords", "title_terms", "abstract_terms", "terms_min",
            "g", "term_strengths", "cutoff_cumul", "kept_terms",
            "only_wos", "only_sco", "both",
            "top_autores", "top_paises", "regiao_tab")) 
  status <- if (exists(o)) "OK"


cat("Valores únicos (amostra):\n")
print(sort(unique(as.vector(adj_top)))[1:20])
cat("Máximo:", max(adj_top), "\n")
cat("Mínimo (fora da diagonal):", min(adj_top[row(adj_top) != col(adj_top)]), "\n")









cat("===== DIAGNÓSTICO: TERMOS DE AFETO/PERCEPÇÃO NA AMOSTRA =====\n\n")

termos_diag <- c(
  "affection", "affective", "affect",
  "emotion", "emotional", "feeling", "mood",
  "perception", "perceived", "perceptual",
  "place attachment", "place identity",
  "well-being", "wellbeing", "mental health"
)

diag_df <- data.frame(
  termo      = termos_diag,
  n_abstract = NA_integer_,
  n_keywords = NA_integer_,
  n_title    = NA_integer_,
  pct        = NA_real_
)

for (i in seq_along(termos_diag)) {
  t <- termos_diag[i]
  pat <- paste0("\\b", gsub(" ", "\\\\s+", t), "s?\\b")
  
  diag_df$n_abstract[i] <- sum(grepl(pat, naive_results$abstract, ignore.case = TRUE), na.rm = TRUE)
  diag_df$n_keywords[i] <- sum(grepl(pat, naive_results$keywords, ignore.case = TRUE), na.rm = TRUE)
  diag_df$n_title[i]    <- sum(grepl(pat, naive_results$title,    ignore.case = TRUE), na.rm = TRUE)
  diag_df$pct[i]        <- round(100 * diag_df$n_abstract[i] / nrow(naive_results), 1)
}

diag_df <- diag_df %>% arrange(desc(n_abstract))
print(diag_df, row.names = FALSE)



cat("\n===== TOP 30 TERMOS DA REDE =====\n")
print(head(term_strengths, 30), row.names = FALSE)

cat("\n===== QUANTOS TERMOS DE AFETO/PERCEPÇÃO ESTÃO NO TOP 100? =====\n")
top100 <- head(term_strengths$term, 100)
afeto_presente <- intersect(top100, c("affection", "affective", "emotion",
                                      "emotional", "feeling", "mood",
                                      "perception", "perceived", "place attachment"))
cat("Presentes:", length(afeto_presente), "\n")
print(afeto_presente)