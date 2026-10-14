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

<img width="913" height="461" alt="image" src="https://github.com/user-attachments/assets/6d8975c4-b8b2-4bfd-a769-4da7166fc5ae" />


## 📚 Aprendizados

### Fundamentos do dbt
- **Estrutura de um projeto dbt:** `dbt_project.yml`, `models/`, `seeds/`, `snapshots/`, `macros/`, `tests/` e `packages.yml`, e o papel de cada um.
- **`profiles.yml` fora do repositório:** a conexão com o Snowflake fica em `~/.dbt/`, longe do código, para que credenciais nunca vão para o Git.
- **Ciclo de comandos:** `dbt deps`, `seed`, `run`, `snapshot`, `test` e `docs`, sempre rodados da pasta que contém o `dbt_project.yml`.

### Modelagem e materializações
- **Camadas:** staging → dim/fct → mart, cada uma com uma responsabilidade clara.
- **Materializações:** `view`, `table`, `incremental` e `ephemeral`, e quando cada uma faz sentido. Configurei por pasta no `dbt_project.yml`, e a configuração mais específica sobrescreve a geral.
- **CTEs:** padrão *importar → transformar*, e a diferença entre o nome da CTE (apelido local) e o nome do modelo.
- **Modelos incrementais:** processar só dados novos com `is_incremental()` e `{{ this }}`, e por que um erro dentro desse bloco só aparece a partir da segunda execução.

### Dependências e linhagem
- **`source()` e `ref()`:** o dbt usa essas funções para montar o DAG e decidir a ordem de execução, em vez de eu escrever nomes de tabela fixos.
- **Sources com `identifier`:** dar um nome próprio no dbt a tabelas cruas do `RAW`, sem depender do nome físico.
- **Documentação e linhagem:** `dbt docs generate` e `dbt docs serve` mostram o grafo entre sources, staging, dimensões e fatos.

### Qualidade de dados
- **Testes genéricos** no `schema.yml` e **testes singulares** na pasta `tests/`: o teste passa quando a consulta retorna zero linhas.
- **Macros em Jinja:** criei `no_nulls_in_columns` para reaproveitar a mesma verificação em qualquer modelo.
- **Pacotes:** instalei `dbt_utils` via `packages.yml` e usei `get_filtered_columns_in_relation` e `generate_surrogate_key`. Aprendi a diferença entre função de pacote e função do `adapter`.

### Histórico e dados de referência
- **Snapshots:** guardar o histórico de mudanças com a estratégia `timestamp`, usando chave substituta e `invalidate_hard_deletes`.
- **Seeds:** carregar um CSV pequeno (datas de lançamento) direto pelo dbt.

### Integração com a nuvem
- **Amazon S3 → Snowflake:** os dados brutos saem do S3 e entram no schema `RAW`, e o dbt cuida só da etapa de transformação (ELT).
- **Roles e permissões no Snowflake:** entendi erros de acesso a schemas e a diferença entre o role do dbt (`TRANSFORM`) e o administrador.

### Depuração
- **Ler o SQL compilado** em `target/compiled` para achar o que o Snowflake realmente recebeu.
- **Erros comuns que resolvi:** chaves Jinja a mais, singular vs plural (`source`/`sources`, `package`/`packages`), parênteses em subqueries, tags sem fechamento (`endsnapshot`), nome de tabela com letra sobrando e senha errada no `profiles.yml`.
- **Git e `.gitignore`:** o que ignorar em um projeto dbt (`target/`, `dbt_packages/`, `logs/`, `venv/`) e por que o `.gitignore` não afeta arquivos que já estavam rastreados.

## 👤 Autor

**Gustavo Braga** · [GitHub](https://github.com/Braga1x) · https://www.linkedin.com/in/gustavo-braga-454871409/
