#!/bin/bash
# Script to configure GitHub repository secrets for CI/CD pipeline

echo "🔐 Configuration des GitHub Secrets pour CI/CD"
echo "=============================================="
echo ""
echo "Ce script vous guide pour configurer les secrets nécessaires au pipeline."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) n'est pas installé."
    echo ""
    echo "Installation:"
    echo "  Ubuntu/Debian: sudo apt install gh"
    echo "  macOS: brew install gh"
    echo ""
    echo "Ou configurez manuellement sur GitHub:"
    echo "  https://github.com/Dexteria78/ProjetAppWebAWS/settings/secrets/actions"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Vous n'êtes pas authentifié avec GitHub CLI."
    echo ""
    echo "Exécutez: gh auth login"
    exit 1
fi

echo "✓ GitHub CLI configuré"
echo ""

# Get AWS credentials from user
echo "📝 Entrez vos credentials AWS Academy:"
echo ""

read -p "AWS_ACCESS_KEY_ID: " aws_access_key
read -p "AWS_SECRET_ACCESS_KEY: " aws_secret_key
read -p "AWS_SESSION_TOKEN: " aws_session_token

echo ""
echo "🚀 Configuration des secrets GitHub..."

# Set secrets
gh secret set AWS_ACCESS_KEY_ID -b "$aws_access_key"
gh secret set AWS_SECRET_ACCESS_KEY -b "$aws_secret_key"
gh secret set AWS_SESSION_TOKEN -b "$aws_session_token"

echo ""
echo "✅ Secrets configurés avec succès!"
echo ""
echo "Vérifiez sur: https://github.com/Dexteria78/ProjetAppWebAWS/settings/secrets/actions"
echo ""
echo "🎯 Vous pouvez maintenant déclencher le pipeline en poussant sur main:"
echo "   git add ."
echo "   git commit -m 'feat: enable CI/CD pipeline'"
echo "   git push origin main"
