# AGENTS.md

## Visão do produto

Game Life é um aplicativo Flutter de evolução pessoal gamificada. Ele transforma missões, hábitos, check-ins, sessões de foco, objetivos e projetos em XP, coins, atributos, áreas e progresso de campanha. O aplicativo é local-first, funciona offline e não possui login, backend, Firebase ou sincronização em nuvem.

O alvo configurado no repositório é Android. Preserve o comportamento e os dados locais existentes ao fazer qualquer alteração.

## Arquitetura real

- `lib/main.dart`: inicializa Flutter, abre o banco e prepara notificações antes de executar o app.
- `lib/src/app/`: tema, gate de onboarding e shell principal.
- `lib/src/core/database/`: abertura do SQLite, schema, migrações e seeds idempotentes.
- `lib/src/core/models/`: modelos e conversão de mapas SQLite.
- `lib/src/core/repositories/`: acesso a dados e operações transacionais por domínio.
- `lib/src/core/services/`: regras compartilhadas de progressão, dificuldade, recompensas e notificações.
- `lib/src/core/utils/`: utilitários de período e geração de IDs.
- `lib/src/design_system/`: cores, tipografia, espaçamento e widgets visuais reutilizáveis.
- `lib/src/features/`: telas organizadas por funcionalidade.
- `lib/src/shared/widgets/`: compatibilidade e campos compartilhados.
- `test/`: testes automatizados.
- `docs/PROJECT_STATE.md`: estado verificável do produto, riscos e roteiro manual.

Não há roteador nomeado. `GameLifeApp` abre `AppStartupGate`; depois do onboarding, `AppShell` combina drawer, `PageView` e barra inferior. Fluxos secundários usam `Navigator` com `MaterialPageRoute`. O estado de tela é mantido principalmente com `StatefulWidget` e `FutureBuilder`; não introduza uma biblioteca de gerenciamento de estado sem necessidade comprovada.

## Banco SQLite e preservação de dados

O arquivo persistente é `game_life_release_v1.db`. O sufixo `v1` faz parte da identidade do arquivo e não representa a versão atual do aplicativo. Não o renomeie: isso faria uma instalação existente parecer vazia.

O schema atual é a versão 16. A migração V16 alinha `campaign_milestones` ao modelo de capítulos com `start_date`, `end_date`, `primary_area_id`, `secondary_area_ids` e `chapter_kind`, além do índice de campanha/área/período. O seed de estabilização repara os seis capítulos padrão sem zerar progresso, status, conclusão, linhas extras ou personalizações reconhecidas.

Regras obrigatórias:

1. Nunca use exclusão do banco, reinstalação, `DROP TABLE` ou reset de dados como solução para migração.
2. Toda alteração de schema deve incrementar `_databaseVersion`, atualizar a criação de instalações novas e adicionar uma migração incremental para bancos existentes.
3. Prefira `ALTER TABLE` e `_addColumnIfMissing` para que a migração seja repetível e segura.
4. Seeds executam também na abertura do banco. Devem ser idempotentes e usar marcadores próprios quando necessário.
5. Preserve IDs, progresso, histórico, estado Hardcore existente e valores personalizados do usuário.
6. Teste os caminhos de banco novo e upgrade da versão anterior.
7. Não reutilize um marcador de seed antigo para uma correção nova.

## Regras de domínio sensíveis

- `DifficultyService` é a fonte de verdade para desbloqueio e persistência de dificuldade.
- Uma nova ativação de Hardcore exige sete datas distintas e válidas em `daily_checkins`.
- A validação deve ocorrer dentro da operação que persiste a dificuldade, não somente na interface.
- Usuários que já estejam em Hardcore não devem sofrer downgrade automático. Se saírem do modo, uma futura reativação volta a exigir os sete check-ins.
- `settings.active_difficulty_mode` é o valor canônico; `campaigns.difficulty_mode` é um espelho mantido pelo serviço.

## Convenções do projeto

- Use null safety, `const` quando aplicável e alterações pequenas e focadas.
- Mantenha textos da interface em PT-BR e reutilize o design system.
- Preserve a separação existente: UI em `features`, persistência em `repositories` e regras transversais em `services`.
- Use transações para operações que atualizam mais de uma tabela.
- Use `IdGenerator` e os helpers de leitura dos modelos em vez de criar variações incompatíveis.
- Datas persistidas usam texto ISO-8601 conforme o padrão existente.
- Trate loading, erro e nova tentativa em telas que dependem do banco.
- Confirme referências antes de remover código. Se ainda houver dúvida, mantenha-o e registre a dívida em `docs/PROJECT_STATE.md`.

## Versão e releases

`lib/src/core/app_version.dart` é a fonte compartilhada para a versão exibida na interface e no relatório. O `version` de `pubspec.yaml` continua sendo a fonte usada pelo build Android. Os dois devem permanecer sincronizados.

Em toda release:

1. Atualize `pubspec.yaml` e `AppVersion`.
2. Atualize `CHANGELOG.md` e `docs/PROJECT_STATE.md`.
3. Verifique menu, Sobre e relatório técnico.
4. Não altere por busca cega versões de schema, seeds, funcionalidades, dependências ou comentários históricos, como `Regra V4.3`.

## Fluxo de trabalho

Antes de editar:

```powershell
git status
git branch --show-current
flutter --version
dart --version
flutter pub get
```

Durante o trabalho, formate apenas os arquivos Dart alterados:

```powershell
dart format <arquivos-dart-alterados>
```

Antes de concluir:

```powershell
flutter analyze
flutter test
flutter build apk --debug
git diff --check
git status
```

`flutter pub outdated` é diagnóstico. Não execute `flutter pub upgrade --major-versions` nem atualize dependências em massa sem uma incompatibilidade concreta.

## Arquivos e áreas sensíveis

- `lib/src/core/database/app_database.dart`
- `lib/src/core/database/db_schema.dart`
- `lib/src/core/database/db_seeds.dart`
- `lib/src/core/models/v3_commitment_models.dart`
- `lib/src/core/repositories/campaign_commitment_repository.dart`
- `lib/src/core/repositories/checkin_repository.dart`
- `lib/src/core/repositories/onboarding_repository.dart`
- `lib/src/core/services/difficulty_service.dart`
- `lib/src/features/onboarding/onboarding_screen.dart`
- `lib/src/features/system/system_screen.dart`
- `lib/src/features/campaign/campaign_screen.dart`
- `lib/src/app/app_shell.dart`
- `lib/src/core/app_version.dart`

Não edite manualmente caches, código gerado ou artefatos como `.dart_tool/`, `build/`, `.flutter-plugins-dependencies`, logs do Flutter e arquivos pessoais de IDE. Não faça push direto para `main`; trabalhe em branch, revise o diff e deixe merge para revisão.
