class AttributeSuggestion {
  const AttributeSuggestion({
    required this.attributeId,
    required this.reason,
    required this.weight,
  });

  final String attributeId;
  final String reason;
  final int weight;
}

class AttributeSuggestionService {
  List<AttributeSuggestion> suggest({
    required String title,
    String description = '',
    int limit = 3,
  }) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    final scores = <String, int>{};
    final reasons = <String, String>{};

    void add(String attributeId, int points, String reason) {
      scores[attributeId] = (scores[attributeId] ?? 0) + points;
      reasons.putIfAbsent(attributeId, () => reason);
    }

    for (final rule in _rules) {
      if (rule.keywords.any(text.contains)) {
        for (final attribute in rule.attributes) {
          add(attribute, rule.points, rule.reason);
        }
      }
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((entry) {
      final weight = entry.value.clamp(10, 100).toInt();
      return AttributeSuggestion(
        attributeId: entry.key,
        reason: reasons[entry.key] ?? 'Sugerido pelo texto informado.',
        weight: weight,
      );
    }).toList();
  }

  static const List<_SuggestionRule> _rules = [
    _SuggestionRule(
      keywords: ['treino', 'flexão', 'flexao', 'corrida', 'academia', 'calistenia', 'exercício', 'exercicio'],
      attributes: ['strength', 'vigor', 'discipline'],
      points: 40,
      reason: 'Ligado a esforço físico e constância.',
    ),
    _SuggestionRule(
      keywords: ['estudo', 'estudar', 'leitura', 'ler', 'curso', 'aula', 'inglês', 'ingles'],
      attributes: ['clarity', 'focus', 'discipline'],
      points: 35,
      reason: 'Ligado a aprendizado, clareza e concentração.',
    ),
    _SuggestionRule(
      keywords: ['oração', 'oracao', 'devocional', 'bíblia', 'biblia', 'fé', 'fe'],
      attributes: ['faith', 'discipline', 'clarity'],
      points: 35,
      reason: 'Ligado à vida espiritual e propósito.',
    ),
    _SuggestionRule(
      keywords: ['programar', 'código', 'codigo', 'app', 'projeto', 'portfolio', 'portfólio'],
      attributes: ['focus', 'creativity', 'responsibility'],
      points: 35,
      reason: 'Ligado a projetos, criação e execução.',
    ),
    _SuggestionRule(
      keywords: ['dinheiro', 'dívida', 'divida', 'conta', 'finança', 'financa', 'compras', 'orçamento', 'orcamento'],
      attributes: ['responsibility', 'discipline'],
      points: 35,
      reason: 'Ligado a responsabilidade financeira.',
    ),
    _SuggestionRule(
      keywords: ['organizar', 'limpar', 'arrumar', 'rotina', 'planejar', 'checklist'],
      attributes: ['discipline', 'responsibility', 'focus'],
      points: 30,
      reason: 'Ligado a ordem, rotina e execução.',
    ),
    _SuggestionRule(
      keywords: ['arte', 'música', 'musica', 'foto', 'vídeo', 'video', 'design', 'criar'],
      attributes: ['creativity', 'focus'],
      points: 30,
      reason: 'Ligado a criação e expressão.',
    ),
  ];
}

class _SuggestionRule {
  const _SuggestionRule({
    required this.keywords,
    required this.attributes,
    required this.points,
    required this.reason,
  });

  final List<String> keywords;
  final List<String> attributes;
  final int points;
  final String reason;
}
