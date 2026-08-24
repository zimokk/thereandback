// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lock_screen_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LockScreenSnapshot {

/// "Day N" (§5.3), same counter as the Путь tab.
 int get questDay;/// Meters credited so far. Domain units — integer meters (§11);
/// formatting for display happens in presentation, same as everywhere
/// else (§5.4).
 int get progressMeters; int get totalMeters;/// A short line describing where the traveler currently is.
///
/// Placeholder today: `Segment`/`Landmark`/`map.json` (§6.2) don't exist
/// yet (Phase 6/11), so there is no real region/landmark data to show.
/// [buildLockScreenSnapshot] falls back to "→ {pointB}" — cheap to swap
/// for a real landmark string once that data lands, not a fake answer.
 String get positionLabel;
/// Create a copy of LockScreenSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LockScreenSnapshotCopyWith<LockScreenSnapshot> get copyWith => _$LockScreenSnapshotCopyWithImpl<LockScreenSnapshot>(this as LockScreenSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockScreenSnapshot&&(identical(other.questDay, questDay) || other.questDay == questDay)&&(identical(other.progressMeters, progressMeters) || other.progressMeters == progressMeters)&&(identical(other.totalMeters, totalMeters) || other.totalMeters == totalMeters)&&(identical(other.positionLabel, positionLabel) || other.positionLabel == positionLabel));
}


@override
int get hashCode => Object.hash(runtimeType,questDay,progressMeters,totalMeters,positionLabel);

@override
String toString() {
  return 'LockScreenSnapshot(questDay: $questDay, progressMeters: $progressMeters, totalMeters: $totalMeters, positionLabel: $positionLabel)';
}


}

/// @nodoc
abstract mixin class $LockScreenSnapshotCopyWith<$Res>  {
  factory $LockScreenSnapshotCopyWith(LockScreenSnapshot value, $Res Function(LockScreenSnapshot) _then) = _$LockScreenSnapshotCopyWithImpl;
@useResult
$Res call({
 int questDay, int progressMeters, int totalMeters, String positionLabel
});




}
/// @nodoc
class _$LockScreenSnapshotCopyWithImpl<$Res>
    implements $LockScreenSnapshotCopyWith<$Res> {
  _$LockScreenSnapshotCopyWithImpl(this._self, this._then);

  final LockScreenSnapshot _self;
  final $Res Function(LockScreenSnapshot) _then;

/// Create a copy of LockScreenSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questDay = null,Object? progressMeters = null,Object? totalMeters = null,Object? positionLabel = null,}) {
  return _then(LockScreenSnapshot(
questDay: null == questDay ? _self.questDay : questDay // ignore: cast_nullable_to_non_nullable
as int,progressMeters: null == progressMeters ? _self.progressMeters : progressMeters // ignore: cast_nullable_to_non_nullable
as int,totalMeters: null == totalMeters ? _self.totalMeters : totalMeters // ignore: cast_nullable_to_non_nullable
as int,positionLabel: null == positionLabel ? _self.positionLabel : positionLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LockScreenSnapshot].
extension LockScreenSnapshotPatterns on LockScreenSnapshot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LockScreenSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LockScreenSnapshot() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LockScreenSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _LockScreenSnapshot():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LockScreenSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _LockScreenSnapshot() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int questDay,  int progressMeters,  int totalMeters,  String positionLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LockScreenSnapshot() when $default != null:
return $default(_that.questDay,_that.progressMeters,_that.totalMeters,_that.positionLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int questDay,  int progressMeters,  int totalMeters,  String positionLabel)  $default,) {final _that = this;
switch (_that) {
case _LockScreenSnapshot():
return $default(_that.questDay,_that.progressMeters,_that.totalMeters,_that.positionLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int questDay,  int progressMeters,  int totalMeters,  String positionLabel)?  $default,) {final _that = this;
switch (_that) {
case _LockScreenSnapshot() when $default != null:
return $default(_that.questDay,_that.progressMeters,_that.totalMeters,_that.positionLabel);case _:
  return null;

}
}

}

/// @nodoc


class _LockScreenSnapshot implements LockScreenSnapshot {
  const _LockScreenSnapshot({required this.questDay, required this.progressMeters, required this.totalMeters, required this.positionLabel});
  

/// "Day N" (§5.3), same counter as the Путь tab.
@override final  int questDay;
/// Meters credited so far. Domain units — integer meters (§11);
/// formatting for display happens in presentation, same as everywhere
/// else (§5.4).
@override final  int progressMeters;
@override final  int totalMeters;
/// A short line describing where the traveler currently is.
///
/// Placeholder today: `Segment`/`Landmark`/`map.json` (§6.2) don't exist
/// yet (Phase 6/11), so there is no real region/landmark data to show.
/// [buildLockScreenSnapshot] falls back to "→ {pointB}" — cheap to swap
/// for a real landmark string once that data lands, not a fake answer.
@override final  String positionLabel;

/// Create a copy of LockScreenSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LockScreenSnapshotCopyWith<_LockScreenSnapshot> get copyWith => __$LockScreenSnapshotCopyWithImpl<_LockScreenSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LockScreenSnapshot&&(identical(other.questDay, questDay) || other.questDay == questDay)&&(identical(other.progressMeters, progressMeters) || other.progressMeters == progressMeters)&&(identical(other.totalMeters, totalMeters) || other.totalMeters == totalMeters)&&(identical(other.positionLabel, positionLabel) || other.positionLabel == positionLabel));
}


@override
int get hashCode => Object.hash(runtimeType,questDay,progressMeters,totalMeters,positionLabel);

@override
String toString() {
  return 'LockScreenSnapshot(questDay: $questDay, progressMeters: $progressMeters, totalMeters: $totalMeters, positionLabel: $positionLabel)';
}


}

/// @nodoc
abstract mixin class _$LockScreenSnapshotCopyWith<$Res> implements $LockScreenSnapshotCopyWith<$Res> {
  factory _$LockScreenSnapshotCopyWith(_LockScreenSnapshot value, $Res Function(_LockScreenSnapshot) _then) = __$LockScreenSnapshotCopyWithImpl;
@override @useResult
$Res call({
 int questDay, int progressMeters, int totalMeters, String positionLabel
});




}
/// @nodoc
class __$LockScreenSnapshotCopyWithImpl<$Res>
    implements _$LockScreenSnapshotCopyWith<$Res> {
  __$LockScreenSnapshotCopyWithImpl(this._self, this._then);

  final _LockScreenSnapshot _self;
  final $Res Function(_LockScreenSnapshot) _then;

/// Create a copy of LockScreenSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questDay = null,Object? progressMeters = null,Object? totalMeters = null,Object? positionLabel = null,}) {
  return _then(_LockScreenSnapshot(
questDay: null == questDay ? _self.questDay : questDay // ignore: cast_nullable_to_non_nullable
as int,progressMeters: null == progressMeters ? _self.progressMeters : progressMeters // ignore: cast_nullable_to_non_nullable
as int,totalMeters: null == totalMeters ? _self.totalMeters : totalMeters // ignore: cast_nullable_to_non_nullable
as int,positionLabel: null == positionLabel ? _self.positionLabel : positionLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
