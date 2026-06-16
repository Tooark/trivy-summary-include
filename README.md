# 📦 GitLab include — Trivy + Hadolint + DefectDojo

Include de CI/CD do GitLab que executa varredura de segurança (SCA) com
[Trivy](https://trivy.dev/), lint de Dockerfile com
[Hadolint](https://github.com/hadolint/hadolint) e, opcionalmente, envia os
relatórios para o [DefectDojo](https://www.defectdojo.org/).

## ✨ Recursos

- 🔎 **Trivy SCA** — varredura de **imagem**, **filesystem** e **repositório**:
  - Vulnerabilidades (JSON)
  - Licenças (JSON)
  - SBOM no formato CycloneDX
  - Sumário consolidado de severidades exportado via `dotenv`
  - Gate opcional por severidade (falha o pipeline)
- 🐳 **Hadolint** — lint do Dockerfile com relatório JSON e falha opcional em findings
- 🛡️ **DefectDojo** — reimport idempotente dos relatórios do Trivy e do Hadolint
  (`auto_create_context` + `close_old_findings`)

## 🚀 Como usar

Uso mínimo:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/Tooark/trivy-summary-include/main/.gitlab-ci.yml'
    inputs:
      docker-image: nginx:latest
```

Com DefectDojo habilitado:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/Tooark/trivy-summary-include/main/.gitlab-ci.yml'
    inputs:
      docker-image: registry.example.com/app:latest
      defectdojo-activated: true
      defectdojo-url: 'https://defectdojo.example.com'
      defectdojo-api-key: '$DD_API_KEY'        # defina como variável CI/CD protegida
      defectdojo-product-name: 'Minha Aplicacao'
      defectdojo-product-type-name: 'Aplicacoes Internas'
```

> 💡 Guarde a `defectdojo-api-key` como variável de CI/CD **protegida e mascarada**,
> em vez de deixá-la em texto puro no arquivo.

## 🔧 Inputs

### Trivy

| Input | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `docker-image` | string | — (obrigatório) | Imagem Docker a ser escaneada |
| `trivy-activated` | boolean | `true` | Ativa a varredura do Trivy |
| `stage` | string | `scan` | Stage onde a varredura do Trivy é executada |
| `severity-exit1` | string | `""` | Severidades que fazem o job falhar (exit code 1). Ex.: `CRITICAL,HIGH` |
| `architecture` | string | `""` | Arquitetura alvo (`amd64` ou `arm64`) |

### Hadolint

| Input | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `hadolint-activated` | boolean | `true` | Ativa o lint do Dockerfile |
| `hadolint-stage` | string | `sast` | Stage onde o Hadolint é executado |
| `dockerfile` | string | `Dockerfile` | Caminho do Dockerfile a ser analisado |
| `hadolint-fail-on-findings` | string | `"false"` | Se `true`, o job falha quando há findings |

### DefectDojo

| Input | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `defectdojo-activated` | boolean | `false` | Habilita o envio para o DefectDojo (Trivy e Hadolint) |
| `defectdojo-url` | string | `""` | URL base do DefectDojo |
| `defectdojo-api-key` | string | `""` | API key do DefectDojo (use variável CI/CD) |
| `defectdojo-product-name` | string | `""` | Nome do produto (`auto_create_context`) |
| `defectdojo-engagement-name` | string | `""` | Nome do engagement (padrão `CI/CD`) |
| `defectdojo-product-type-name` | string | `""` | Tipo de produto usado para criar o produto no primeiro envio |
| `defectdojo-trivy-product-type-name` | string | `"Trivy Scan"` | Tipo de produto para uploads do Trivy |
| `defectdojo-hadolint-product-type-name` | string | `"Hadolint Dockerfile check"` | Tipo de produto para uploads do Hadolint |
| `defectdojo-engagement-id` | string | `""` | ID do engagement (fallback quando os nomes não são usados) |

## 🧩 Stages

O include declara os seguintes stages:

1. `sast` (configurável via `hadolint-stage`) — Hadolint
2. `scan` — Trivy
3. `sca`

## 📦 Artefatos gerados

| Arquivo | Conteúdo |
|---------|----------|
| `sca-container-scanning-report.json` | Vulnerabilidades da imagem |
| `sca-container-license-report.json` | Licenças da imagem |
| `sca-container-sbom.cyclonedx.json` | SBOM da imagem (CycloneDX) |
| `sca-fs-scanning-report.json` | Vulnerabilidades do filesystem |
| `sca-fs-license-report.json` | Licenças do filesystem |
| `sca-fs-sbom.cyclonedx.json` | SBOM do filesystem (CycloneDX) |
| `sca-repo-scanning-report.json` | Vulnerabilidades do repositório |
| `sca-repo-license-report.json` | Licenças do repositório |
| `sca-repo-sbom.cyclonedx.json` | SBOM do repositório (CycloneDX) |
| `hadolint-report.json` | Findings do Hadolint |
| `variables.env` | Contagens de severidade (`dotenv`) |

As contagens exportadas em `variables.env` (disponíveis para jobs seguintes via
`dotenv`) são: `CRITICAL_COUNT`, `HIGH_COUNT`, `MEDIUM_COUNT`, `LOW_COUNT`,
`UNKNOWN_COUNT` e `TOTAL_COUNT`.

## 🛡️ DefectDojo

Quando `defectdojo-activated: true`, os relatórios são enviados pelo endpoint
`reimport-scan` de forma idempotente:

- `auto_create_context=true` — cria produto/engagement no primeiro envio
- `close_old_findings=true` — fecha findings antigos a cada execução
- O Trivy é enviado como `Trivy Scan` e o Hadolint como `Hadolint Dockerfile check`

Se o produto ainda não existir, `defectdojo-product-type-name` é obrigatório para
criá-lo. Como alternativa aos nomes, é possível informar `defectdojo-engagement-id`.
