import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/widgets/gl_card.dart';
import '../../shared/widgets/gl_primary_button.dart';
import '../missions/mission_form_screen.dart';
import '../missions/mission_list_screen.dart';
import '../objectives/objective_form_screen.dart';
import '../objectives/objective_list_screen.dart';
import '../projects/project_form_screen.dart';
import '../projects/project_list_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late Future<_JourneyData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_JourneyData> _load() async {
    final db = await AppDatabase.instance.database;

    final missions = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM missions WHERE is_active = 1;',
    );
    final missionCompletions = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM mission_completions;',
    );
    final activeObjectives = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM objectives WHERE status = 'active';",
    );
    final completedObjectives = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM objectives WHERE status = 'completed';",
    );
    final activeProjects = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM projects WHERE status IN ('active', 'paused');",
    );
    final completedProjects = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM projects WHERE status = 'completed';",
    );

    return _JourneyData(
      missionCount: missions.first['total'] as int? ?? 0,
      missionCompletionCount: missionCompletions.first['total'] as int? ?? 0,
      activeObjectiveCount: activeObjectives.first['total'] as int? ?? 0,
      completedObjectiveCount: completedObjectives.first['total'] as int? ?? 0,
      activeProjectCount: activeProjects.first['total'] as int? ?? 0,
      completedProjectCount: completedProjects.first['total'] as int? ?? 0,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openMissionList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MissionListScreen()),
    );
    if (mounted) _reload();
  }

  Future<void> _openMissionForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MissionFormScreen()),
    );

    if (created == true) _reload();
  }

  Future<void> _openObjectiveList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ObjectiveListScreen()),
    );
    if (mounted) _reload();
  }

  Future<void> _openObjectiveForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ObjectiveFormScreen()),
    );

    if (created == true) _reload();
  }

  Future<void> _openProjectList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectListScreen()),
    );
    if (mounted) _reload();
  }

  Future<void> _openProjectForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
    );

    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_JourneyData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            GlCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jornada',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Central de missões, objetivos e projetos. Missões sustentam a rotina, objetivos medem metas e projetos organizam entregas maiores.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlPrimaryButton(
              label: 'Nova missão',
              icon: Icons.add_rounded,
              onPressed: _openMissionForm,
            ),
            const SizedBox(height: 10),
            GlPrimaryButton(
              label: 'Ver missões',
              icon: Icons.flag_rounded,
              onPressed: _openMissionList,
            ),
            const SizedBox(height: 10),
            GlPrimaryButton(
              label: 'Novo objetivo',
              icon: Icons.track_changes_rounded,
              onPressed: _openObjectiveForm,
            ),
            const SizedBox(height: 10),
            GlPrimaryButton(
              label: 'Ver objetivos',
              icon: Icons.add_chart_rounded,
              onPressed: _openObjectiveList,
            ),
            const SizedBox(height: 10),
            GlPrimaryButton(
              label: 'Novo projeto',
              icon: Icons.folder_special_rounded,
              onPressed: _openProjectForm,
            ),
            const SizedBox(height: 10),
            GlPrimaryButton(
              label: 'Ver projetos',
              icon: Icons.view_list_rounded,
              onPressed: _openProjectList,
            ),
            const SizedBox(height: 16),
            _CounterCard(
              title: 'Missões ativas',
              value: data?.missionCount ?? 0,
              icon: Icons.flag_rounded,
              onTap: _openMissionList,
            ),
            const SizedBox(height: 10),
            _CounterCard(
              title: 'Conclusões de missão',
              value: data?.missionCompletionCount ?? 0,
              icon: Icons.check_circle_rounded,
              onTap: _openMissionList,
            ),
            const SizedBox(height: 10),
            _CounterCard(
              title: 'Objetivos ativos',
              value: data?.activeObjectiveCount ?? 0,
              icon: Icons.track_changes_rounded,
              onTap: _openObjectiveList,
            ),
            const SizedBox(height: 10),
            _CounterCard(
              title: 'Objetivos concluídos',
              value: data?.completedObjectiveCount ?? 0,
              icon: Icons.emoji_events_rounded,
              onTap: _openObjectiveList,
            ),
            const SizedBox(height: 10),
            _CounterCard(
              title: 'Projetos ativos/pausados',
              value: data?.activeProjectCount ?? 0,
              icon: Icons.folder_special_rounded,
              onTap: _openProjectList,
            ),
            const SizedBox(height: 10),
            _CounterCard(
              title: 'Projetos concluídos',
              value: data?.completedProjectCount ?? 0,
              icon: Icons.workspace_premium_rounded,
              onTap: _openProjectList,
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyData {
  const _JourneyData({
    required this.missionCount,
    required this.missionCompletionCount,
    required this.activeObjectiveCount,
    required this.completedObjectiveCount,
    required this.activeProjectCount,
    required this.completedProjectCount,
  });

  final int missionCount;
  final int missionCompletionCount;
  final int activeObjectiveCount;
  final int completedObjectiveCount;
  final int activeProjectCount;
  final int completedProjectCount;
}
