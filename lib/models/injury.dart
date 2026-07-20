/// Every tappable zone on the body diagram (`InteractiveInjuryBody`) — see
/// `lib/widgets/body/body_geometry.dart`'s `BodySilhouette.injuryZones()`
/// for where each one is positioned.
enum InjuryBodyPart {
  head,
  neck,
  chest,
  upperBack,
  abdomen,
  lowerBack,
  pelvis,
  leftShoulder,
  leftUpperArm,
  leftElbow,
  leftForearm,
  leftWrist,
  rightShoulder,
  rightUpperArm,
  rightElbow,
  rightForearm,
  rightWrist,
  leftHip,
  leftThigh,
  leftKnee,
  leftCalf,
  leftAnkle,
  rightHip,
  rightThigh,
  rightKnee,
  rightCalf,
  rightAnkle,
}

enum InjuryType {
  sprain,
  strain,
  bruise,
  fracture,
  dislocation,
  tendinitis,
  cramp,
  soreness,
  other,
}

/// A single logged injury/sensation at a body part — title/description text
/// is resolved via `lib/logic/injury_labels.dart` (this model has no
/// `BuildContext`, same split as [AchievementDef]/`StatusResult`).
class Injury {
  const Injury({
    required this.id,
    required this.bodyPart,
    required this.type,
    required this.description,
    required this.date,
  });

  final String id;
  final InjuryBodyPart bodyPart;
  final InjuryType type;
  final String description;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'bodyPart': bodyPart.name,
        'type': type.name,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Injury.fromJson(Map<String, dynamic> json) => Injury(
        id: json['id'] as String,
        bodyPart: InjuryBodyPart.values.byName(json['bodyPart'] as String),
        type: InjuryType.values.byName(json['type'] as String),
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}
