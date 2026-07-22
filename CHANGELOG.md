# Changelog

Todas as mudanças relevantes do Game Life são registradas neste arquivo. A estrutura segue o formato do Keep a Changelog, adaptado para incluir o build do aplicativo.

## [Unreleased]

### Planejado

- V4.6: ligar objetivos aos capítulos da campanha.

## [V4.5.1+58] - 2026-07-22

### Adicionado

- Fonte compartilhada para a versão exibida no menu, na tela Sobre e no relatório técnico.
- `AGENTS.md` com regras de arquitetura, migração, preservação de dados e validação.
- `docs/PROJECT_STATE.md` com estado do produto, riscos e roteiro manual.
- Migração SQLite V16 para os campos de período, áreas e tipo dos capítulos.
- Testes SQLite em memória para migração, seed, leitura dos capítulos e a regra Hardcore.

### Corrigido

- Compatibilidade entre o modelo de capítulo, o schema SQLite e as operações do repositório.
- Preparação e reparo idempotente dos seis capítulos padrão, preservando progresso e dados existentes.
- Bloqueio real do modo Hardcore na camada de persistência: novas ativações exigem sete check-ins válidos e distintos.
- Estados de falha e nova tentativa da Campanha, além da espera real no refresh e do feedback de sincronização.
- Progresso automático dos capítulos protegido contra regressão e seed resiliente à ausência da campanha padrão.
- Textos da Campanha que apontavam para um editor/configuração inexistente.
- Atalho da Campanha com barra de navegação e dificuldade exibida a partir da configuração canônica.
- Consistência da versão `4.5.1+58` entre build, menu, Sobre e relatório.

### Alterado

- O progresso do desbloqueio Hardcore é compartilhado pelas interfaces de onboarding e Configurações.
- Usuários que já estavam em Hardcore são preservados; uma reativação futura, após sair do modo, exige o requisito vigente.
- A Campanha permanece somente de leitura; sincronização e refresh não reintroduzem o editor amplo nem controles manuais de capítulo.
- Telas antigas e duplicadas de Jornada, Campanha e Evolução foram mantidas e registradas como dívida técnica, sem limpeza arquitetural ampla nesta estabilização.
- `sqflite_common_ffi` foi adicionado apenas como dependência de desenvolvimento para validar bancos SQLite reais nos testes de VM.

## [V4.5.0+57] - 2026-07-14

### Alterado

- Campanha reformulada como experiência visual e narrativa centrada no capítulo atual, mapa de capítulos, sinais de progresso e critérios de vitória.
- Editor amplo de campanha e formulário de capítulos removidos da navegação principal.
- Tela Sobre atualizada para refletir Capítulos V1, áreas e a nova experiência da campanha.

## [V4.4.0+56] - 2026-07-06

### Adicionado

- Snapshot de Capítulos Lite presente no commit inicial do repositório.

### Contexto

- Registrada como a última versão validada manualmente segundo o briefing desta sprint. Essa validação não é comprovada pelo histórico Git disponível.

## [V4.3.0+55] - 2026-07-07

### Contexto

- Checkpoint estável comprovado pelo commit `6c75349` (`checkpoint: stable v4.3`).
- O checkpoint restaurou identificação V4.3 no pubspec, menu e tela Sobre.
