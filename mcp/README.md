# Serveurs MCP du niveau 5

Aucun serveur à coder : on utilise deux serveurs publics.

| Serveur | URL | Authentification |
|---|---|---|
| Wikipedia | `https://wikipedia-mcp.vercel.app/mcp` | aucune, déclaré dans `env/sbxenv.mcp.yaml` |
| Context7 | `https://mcp.context7.com/mcp` | clé d'API personnelle, gardée sur l'hôte |

## Enregistrer Context7 (sur l'hôte, une fois)

```bash
# 1. La clé va dans le coffre de l'hôte (jamais dans la VM)
read -rs CONTEXT7_API_KEY && printf '%s' "$CONTEXT7_API_KEY" | sbx secret set mcp:context7:api-key --force && unset CONTEXT7_API_KEY
# 2. Le serveur, avec un header qui référence le secret (quotes simples : ${api-key} est un placeholder sbx)
sbx mcp add context7 --url https://mcp.context7.com/mcp --header 'CONTEXT7_API_KEY: ${api-key}'
sbx mcp inspect context7
```

## Nettoyage

```bash
sbx mcp rm context7 && sbx secret rm mcp:context7:api-key
sbx mcp rm wikipedia
```
