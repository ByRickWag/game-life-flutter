# Estado do projeto Game Life

Atualizado em: 2026-07-22

## Identificação

- Versão atual: **V4.5.1+58 — Estabilização da Campanha e do Repositório**.
- Última versão validada manualmente: **V4.4.0+56**, segundo o briefing desta sprint.
- Evidência do repositório: V4.4.0+56 existe como snapshot inicial, mas o Git não comprova sua validação manual. O commit `6c75349` comprova um checkpoint denominado `stable v4.3`.
- Próximo passo sugerido: **V4.6 — Objetivos ligados aos capítulos**.

## Stack e plataformas

- Flutter 3.44.5, canal stable.
- Dart 3.12.2; o `pubspec.yaml` exige SDK `^3.12.2`.
- Material Design com design system próprio em Dart.
- SQLite local com `sqflite` e migrações incrementais.
- Notificações locais com `flutter_local_notifications` e `timezone`.
- Android é a plataforma configurada no repositório.
- O aplicativo é local-first e offline: não há login, Firebase, backend, API remota ou sincronização em nuvem.

## Arquitetura

O startup abre o banco e inicializa notificações antes de executar `GameLifeApp`. `AppStartupGate` consulta o estado do onboarding e mostra onboarding ou `AppShell`. O shell usa drawer para grupos, `PageView` para páginas do grupo e uma barra inferior para a navegação local. Telas secundárias são abertas com `Navigator` e `MaterialPageRoute`; não há named routes ou deep links.

As telas mantêm estado com widgets Flutter e `FutureBuilder`. Repositórios concentram operações SQLite; serviços concentram regras reutilizáveis. O banco executa criação/migração e seeds idempotentes ao abrir.

## Navegação principal

| Grupo | Páginas |
| --- | --- |
| Início | Dashboard, Ações rápidas, Ritmo diário |
| Jornada | Missões, Hábitos, Saúde, Objetivos, Campanha |
| Foco | Registrar sessão, Sessões recentes, Resumo de foco |
| Finanças | Cofre do Reino, Loja do Reino |
| Projetos | Projetos ativos, Tarefas, Projetos concluídos |
| Evolução | Herói, Áreas, Atributos, Conquistas, Relatório |
| Sistema | Histórico, Configurações, Sobre |

## Módulos implementados

- Onboarding e configuração inicial.
- Dashboard e check-in diário.
- Missões compostas e tarefas.
- Hábitos, hidratação e limites de alimentação.
- Objetivos mensuráveis.
- Sessões manuais e timer de foco.
- Projetos, marcos e tarefas.
- Campanha, capítulos e progresso automático.
- XP, níveis, coins, atributos, áreas e conquistas.
- Cofres, movimentações e Loja do Reino.
- Histórico, relatório técnico, lembretes e balanceamento local.

## Estado da Campanha e do banco

O schema atual é **16**. A V16 adiciona de forma não destrutiva a `campaign_milestones`:

- `start_date TEXT`;
- `end_date TEXT`;
- `primary_area_id TEXT`;
- `secondary_area_ids TEXT`, com fallback seguro vazio;
- `chapter_kind TEXT NOT NULL DEFAULT 'chapter'`;
- índice `idx_campaign_chapters_area` sobre campanha, área principal e período.

A migração usa verificação de coluna antes de `ALTER TABLE` e atende tanto instalações novas quanto upgrades com `oldVersion < 16`.

O seed V451 usa marcador próprio e prepara/repara os seis IDs padrão da campanha Transformação dos 20 aos 25: Prólogo e Capítulos 1 a 5. Ele completa datas, áreas, ordem, automação e tipo de capítulo sem zerar `progress`, `status` ou `completed_at`, sem remover capítulos extras e sem sobrescrever conteúdo reconhecido como personalizado. Também recupera com segurança a campanha padrão caso a linha-pai esteja ausente, sem desativar outra campanha do usuário. A preferência `campaign_visual_unit=chapters` é criada apenas quando ausente.

A tela ativa é `features/campaign/campaign_screen.dart`. Ela apresenta leitura narrativa, capítulo atual, critérios de vitória, sinais reais, mapa dos seis capítulos e sincronização. A experiência permanece somente de leitura: não existe editor amplo na navegação principal nem controle para concluir/reabrir capítulos manualmente. Falhas de carregamento oferecem mensagem e nova tentativa; refresh e sincronização aguardam o trabalho real e apresentam feedback. A sincronização automática nunca reduz um progresso já registrado.

## Regra Hardcore

`DifficultyService` é a fonte única de verdade. Hardcore exige **sete check-ins válidos**, calculados por datas distintas, não vazias e válidas em `daily_checkins`.

- `hardcoreRequiredCheckIns` define o requisito 7.
- A elegibilidade informa quantidade válida, requisito, desbloqueio, progresso e quantidade restante.
- `setActiveMode()` revalida dentro da transação antes de gravar configuração, campanha ou histórico.
- Onboarding e Configurações exibem o mesmo progresso e impedem a seleção quando bloqueado.
- `settings.active_difficulty_mode` é canônico; `campaigns.difficulty_mode` é sincronizado como espelho.
- Um usuário que já esteja em Hardcore é preservado mesmo com menos de sete registros. Não há downgrade automático. Após mudar para outro modo, uma nova ativação exige o requisito atual.

## Limitações e riscos conhecidos

- Login, nuvem, sincronização entre aparelhos e backend continuam fora do escopo.
- Apenas Android está configurado e validado como alvo deste repositório.
- Banco e notificações são inicializados antes de `runApp`; uma falha nessa etapa ainda não possui tela de recuperação.
- `pubspec.yaml` e `AppVersion` precisam ser atualizados juntos em releases.
- A cobertura automatizada é focada nas regras estabilizadas; a validação visual e de upgrade com dados reais ainda depende do roteiro manual.
- `sqflite_common_ffi` existe somente em `dev_dependencies` para os testes de migração; o aplicativo Android continua usando `sqflite`.
- O relatório técnico expõe o caminho local do banco para diagnóstico; evite compartilhá-lo sem revisar o conteúdo.

## Código legado mantido

Os arquivos abaixo não estão no grafo de navegação iniciado por `lib/main.dart`, mas foram preservados nesta sprint para evitar uma limpeza arquitetural ampla:

- `lib/src/features/journey/journey_screen.dart`;
- `lib/src/features/journey/v2_journey_pages.dart`;
- `lib/src/features/evolution/evolution_screen.dart`;
- `lib/src/features/dashboard/evolution/evolution_screen.dart`;
- `lib/src/features/dashboard/evolution/v2_evolution_pages.dart`.

O arquivo ativo `lib/src/features/v2_navigation/v2_group_pages.dart` ainda possui as classes sem referência `V2CampaignPage`, `V2HeroPage`, `V2ReportPage`, `V2HistoryHubPage` e `V2AboutPage`. A tela ativa de Evolução é `lib/src/features/evolution/v2_evolution_pages.dart`.

## Roteiro mínimo de validação manual

Use um emulador ou aparelho com uma cópia segura dos dados da versão anterior.

1. Abra o app com dados já existentes.
2. Confirme que missões, objetivos, hábitos, sessões, projetos, XP, coins, histórico e configurações foram preservados.
3. Abra **Jornada > Campanha**.
4. Confira os seis capítulos, a ordem Prólogo/1–5, datas e áreas.
5. Confira o capítulo atual, progresso, status e critérios de vitória.
6. Use **Sincronizar progresso automático** e confirme a atualização sem perda de dados.
7. Quando viável, simule uma falha de carregamento/sincronização e valide a mensagem e **Tentar novamente**.
8. Com menos de sete check-ins válidos, abra **Sistema > Configurações**.
9. Confirme que Hardcore aparece bloqueado e mostra o progresso atual, por exemplo `3 de 7 check-ins`.
10. Tente ativar Hardcore e confirme que tanto a interface quanto a persistência recusam a alteração.
11. Repita o fluxo com sete ou mais datas válidas de check-in.
12. Confirme que Hardcore pode ser ativado.
13. Reinicie o aplicativo e confirme que a dificuldade persistiu.
14. Abra **Sobre**, o menu e o relatório técnico.
15. Confirme `V4.5.1+58` no menu e `4.5.1+58` no Sobre/relatório, além do build 58 instalado.
16. Percorra Dashboard, Jornada, Foco, Finanças, Projetos, Evolução e Sistema para procurar regressões visuais evidentes.

Para uma instalação nova, repita os itens da Campanha e confirme que o banco nasce diretamente no schema 16. Para um usuário que já estava em Hardcore, confirme separadamente que a abertura do app não provoca downgrade.

## Validação automatizada esperada

Antes de considerar uma alteração pronta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Os testes desta estabilização devem cobrir, no mínimo, bloqueio e liberação do Hardcore, preservação de Hardcore legado, leitura dos campos de capítulo e migração/reparo dos seis capítulos sem perda de progresso.
