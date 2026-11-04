/// Encuesta adjunta a una publicación del foro (estilo Twitter).
class ForumPollOption {
  const ForumPollOption({
    required this.id,
    required this.text,
    this.votes = const [],
  });

  final String id;
  final String text;

  /// uids de quienes votaron esta opción.
  final List<String> votes;

  bool hasVoteFrom(String? uid) => uid != null && votes.contains(uid);

  factory ForumPollOption.fromMap(Map<String, dynamic> map) {
    return ForumPollOption(
      id: (map['id'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      votes: ((map['votes'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'votes': votes};
  }
}

class ForumPollModel {
  const ForumPollModel({required this.options});

  final List<ForumPollOption> options;

  int get totalVotes =>
      options.fold(0, (total, option) => total + option.votes.length);

  bool get isValid => options.length >= 2;

  bool hasVotedBy(String? uid) {
    if (uid == null) return false;
    return options.any((option) => option.hasVoteFrom(uid));
  }

  /// Porcentaje (0..1) de votos de una opción.
  double percentageOf(ForumPollOption option) {
    final total = totalVotes;
    if (total == 0) return 0;
    return option.votes.length / total;
  }

  /// Devuelve la encuesta con el voto del usuario aplicado.
  ///
  /// Si ya había votado otra opción, el voto anterior se retira.
  ForumPollModel vote(String optionId, String uid) {
    final updated = options.map((option) {
      final votes = option.votes.where((id) => id != uid).toList();
      if (option.id == optionId) votes.add(uid);
      return ForumPollOption(id: option.id, text: option.text, votes: votes);
    }).toList(growable: false);
    return ForumPollModel(options: updated);
  }

  factory ForumPollModel.fromMap(Map<String, dynamic> map) {
    final rawOptions = (map['options'] as List?) ?? const [];
    return ForumPollModel(
      options: rawOptions
          .whereType<Map>()
          .map((item) => ForumPollOption.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'options': options.map((option) => option.toMap()).toList(growable: false),
    };
  }
}
