class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute});

  final int hour;
  final int minute;

  TimeOfDayValue copyWith({int? hour, int? minute}) {
    return TimeOfDayValue(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toMap() => {
        'hour': hour,
        'minute': minute,
      };

  factory TimeOfDayValue.fromMap(Map<String, dynamic> map) {
    return TimeOfDayValue(
      hour: map['hour'] as int? ?? 0,
      minute: map['minute'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDayValue &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'TimeOfDayValue(hour: $hour, minute: $minute)';
}

