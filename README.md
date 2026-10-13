# 🎬 Pipeline ELT com Amazon S3, Snowflake e dbt

Projeto de engenharia de dados que leva dados do **Amazon S3** até modelos analíticos no **Snowflake**, com as transformações feitas em **dbt**. Cobre o ciclo ELT: ingestão, fontes, modelagem dimensional, materializações, snapshots, testes automatizados e documentação.

> Projeto desenvolvido durante um curso de dbt: [nome do curso/instrutor](https://www.youtube.com/watch?v=zZVQluYDwYY).

## 🛠️ Stack

| Camada | Tecnologia |
|---|---|
| Armazenamento | Amazon S3 |
| Data warehouse | Snowflake |
| Transformação | dbt Core 1.12 (`dbt-snowflake`) + `dbt_utils` 1.3.0 |
| Linguagens | SQL e Jinja |
| Ambiente | Python (venv) e Git |

## 🏗️ Arquitetura

```
Amazon S3 (arquivos brutos)
      │   [stage externo + COPY INTO]
      ▼
Snowflake · MOVIELENS.RAW  (6 tabelas cruas)
      │   dbt
      ▼
staging (views) → dim (tables) / fct (incremental) → mart
```

## 📥 Ingestão (S3 → Snowflake)

Os arquivos do dataset MovieLens ficam no S3 e são carregados no schema `RAW` do Snowflake:

- [Bucket/pasta e formato dos arquivos]
- [Como foi feita a conexão: storage integration ou credenciais, stage externo e `COPY INTO`]

Tabelas cruas: `raw_movies`, `raw_ratings`, `raw_tags`, `raw_links`, `raw_genome_tags`, `raw_genome_scores`.

## 🗂️ Estrutura

```
netflix/
├── models/
│   ├── staging/    # src_*: limpeza e renomeação (views)
│   ├── dim/        # dimensões (tables)
│   ├── fct/        # fatos (incremental)
│   ├── mart/       # [o que a camada mart entrega]
│   ├── source.yml
│   └── schema.yml  # testes e documentação
├── snapshots/      # snap_tags
├── seeds/          # seed_movie_release_dates.csv
├── macros/         # no_nulls_in_columns
├── tests/          # relevance_score_test
└── packages.yml
```

## ✅ O que foi implementado

- **Sources:** as 6 tabelas do `RAW` declaradas em `source.yml` e lidas com `{{ source() }}`.
- **Staging:** um modelo `src_*` por tabela, com CTEs e colunas renomeadas (`movieId` → `movie_id`), materializado como **view**.
- **Modelagem dimensional:** `dim_movies`, `dim_users` e `dim_genome_tags` como **table**; `fct_ratings` e `fct_genome_scores` como fatos.
- **Incremental:** `fct_ratings` processa só avaliações com `rating_timestamp` maior que o último já carregado (`on_schema_change = 'fail'`).
- **Mart:** [descreva os modelos, por exemplo `dim_movies_with_tags`].
- **Snapshot:** `snap_tags` com estratégia `timestamp` e chave gerada por `dbt_utils.generate_surrogate_key`.
- **Seed:** `seed_movie_release_dates.csv`.
- **Testes automatizados:**
  - genéricos no `schema.yml` [liste os que usou];
  - macro `no_nulls_in_columns`, baseada em `dbt_utils.get_filtered_columns_in_relation`;
  - teste singular `relevance_score_test`, que aplica a macro ao `fct_genome_scores`.
- **Documentação:** `dbt docs generate` e `dbt docs serve`, com grafo de linhagem.

## 🚀 Como executar

1. **Pré-requisitos:** conta Snowflake, bucket S3 com os dados já carregados no schema `RAW`, Python 3.
2. **Ambiente**
```bash
   git clone https://github.com/Braga1x/dbt-snowflake-netflix-pipeline.git
   cd dbt-snowflake-netflix-pipeline
   python -m venv venv
   source venv/Scripts/activate   # Windows (Git Bash)
   pip install dbt-snowflake
```
3. **Conexão** em `~/.dbt/profiles.yml` (fora do repositório, pois tem credenciais):
```yaml
   netflix:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: <sua_conta>
         user: <seu_usuario>
         password: <sua_senha>
         role: TRANSFORM
         database: MOVIELENS
         warehouse: COMPUTE_WH
         schema: DEV
         threads: 1
```
4. **Rodar** (dentro de `netflix/`, onde está o `dbt_project.yml`)
```bash
   dbt deps
   dbt seed
   dbt run
   dbt snapshot
   dbt test
   dbt docs generate && dbt docs serve
```

## 📸 Linhagem

[Print do grafo do `dbt docs serve`]

## 📚 Aprendizados

- Diferença entre CTE, view, table, incremental e ephemeral
- `source()` e `ref()` para o dbt montar a ordem de execução
- Macros e testes reaproveitando lógica de qualidade de dados
- Depuração de erros lendo o SQL compilado em `target/compiled`

## 👤 Autor

**Gustavo Braga** · [GitHub](https://github.com/Braga1x) · [LinkedIn]
