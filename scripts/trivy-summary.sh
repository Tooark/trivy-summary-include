#!/bin/bash

TRIVY_JSON="$1"
IMAGE_TAG="$2"
SUMMARY_FILE="trivy-summary.md"

apt-get update && apt-get install -y jq

if [ ! -s "$TRIVY_JSON" ]; then
  echo "⚠️ Arquivo JSON do Trivy não encontrado ou está vazio. As contagens serão zero."
  CRITICAL_COUNT=0
  HIGH_COUNT=0
  MEDIUM_COUNT=0
  LOW_COUNT=0
  UNKNOWN_COUNT=0
  TOTAL_COUNT=0
else
  CRITICAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$TRIVY_JSON")
  HIGH_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$TRIVY_JSON")
  MEDIUM_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$TRIVY_JSON")
  LOW_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$TRIVY_JSON")
  UNKNOWN_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "UNKNOWN")] | length' "$TRIVY_JSON")
  TOTAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$TRIVY_JSON")
fi

# Imprime no log
echo "🔍 Imagem escaneada: $IMAGE_TAG"
echo "🚨 Críticas: $CRITICAL_COUNT | 🔴 Altas: $HIGH_COUNT | 🟠 Médias: $MEDIUM_COUNT | 🟡 Baixas: $LOW_COUNT | ⚪ Desconhecidas: $UNKNOWN_COUNT"
echo "📊 Total de vulnerabilidades: $TOTAL_COUNT"

# Gera o resumo em Markdown
{
  echo "### 🔍 Sumário de Vulnerabilidades da Imagem"
  echo ""
  echo "**Imagem escaneada:** \`$IMAGE_TAG\`"
  echo ""
  echo "| Severidade     | Contagem |"
  echo "|----------------|----------|"
  echo "| 🚨 Críticas     | **$CRITICAL_COUNT** |"
  echo "| 🔴 Altas        | $HIGH_COUNT |"
  echo "| 🟠 Médias       | $MEDIUM_COUNT |"
  echo "| 🟡 Baixas       | $LOW_COUNT |"
  echo "| ⚪ Desconhecidas| $UNKNOWN_COUNT |"
  echo "| 📊 **Total**    | **$TOTAL_COUNT** |"
  echo ""
  echo "---"
  echo "### 📋 Detalhes das Vulnerabilidades"
  echo ""

  if [ -s "$TRIVY_JSON" ]; then
    jq -c '.Results[]?.Vulnerabilities[]? | select(.VulnerabilityID != null)' "$TRIVY_JSON" | while read -r vuln; do
      VULN_ID=$(echo "$vuln" | jq -r '.VulnerabilityID')
      SEVERITY=$(echo "$vuln" | jq -r '.Severity')
      PKG_NAME=$(echo "$vuln" | jq -r '.PkgName')
      INSTALLED_VER=$(echo "$vuln" | jq -r '.InstalledVersion')
      FIXED_VER=$(echo "$vuln" | jq -r '.FixedVersion // "N/A"')
      STATUS=$(echo "$vuln" | jq -r '.Status // "N/A"')
      TITLE=$(echo "$vuln" | jq -r '.Title // "N/A"')
      DESCRIPTION=$(echo "$vuln" | jq -r '.Description // "N/A" | .[:200] + (if (. | length) > 200 then "..." else "" end)')

      echo "#### $VULN_ID"
      echo "- **Severidade:** $SEVERITY"
      echo "- **Pacote:** \`$PKG_NAME\` (\`$INSTALLED_VER\`)"
      echo "- **Correção:** \`$FIXED_VER\`"
      echo "- **Status:** \`$STATUS\`"
      echo "- **Título:** $TITLE"
      echo "- **Descrição:** $DESCRIPTION"
      echo ""
    done
  else
    echo "_Nenhuma vulnerabilidade detalhada para exibir._"
  fi
} > "$SUMMARY_FILE"

echo "CRITICAL_COUNT=$CRITICAL_COUNT" >> trivy-counts.env
echo "HIGH_COUNT=$HIGH_COUNT" >> trivy-counts.env
echo "MEDIUM_COUNT=$MEDIUM_COUNT" >> trivy-counts.env
echo "LOW_COUNT=$LOW_COUNT" >> trivy-counts.env
echo "UNKNOWN_COUNT=$UNKNOWN_COUNT" >> trivy-counts.env
echo "TOTAL_COUNT=$TOTAL_COUNT" >> trivy-counts.env
