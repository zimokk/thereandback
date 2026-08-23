// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SelectedQuest {

 String get journeyId;/// When the user tapped "Start quest".
 DateTime get startedAt;/// Start of the sync window not yet applied to [progressMeters]. Seeded
/// to the start of the local calendar day on quest start (§5.2), so
/// steps already taken that day still count.
 DateTime get lastSyncedAt;/// Total meters credited to this quest so far. Monotonically
/// non-decreasing — see `steps/domain/stride.dart`'s
/// `clampNonDecreasing`.
 int get progressMeters;
/// Create a copy of SelectedQuest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedQuestCopyWith<SelectedQuest> get copyWith => _$SelectedQuestCopyWithImpl<SelectedQuest>(this as SelectedQuest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedQuest&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.progressMeters, progressMeters) || other.progressMeters == progressMeters));
}


@override
int get hashCode => Object.hash(runtimeType,journeyId,startedAt,lastSyncedAt,progressMeters);

@override
String toString() {
  return 'SelectedQuest(journeyId: $journeyId, startedAt: $startedAt, lastSyncedAt: $lastSyncedAt, progressMeters: $progressMeters)';
}


}

/// @nodoc
abstract mixin class $SelectedQuestCopyWith<$Res>  {
  factory $SelectedQuestCopyWith(SelectedQuest value, $Res Function(SelectedQuest) _then) = _$SelectedQuestCopyWithImpl;
@useResult
$Res call({
 String journeyId, DateTime startedAt, DateTime lastSyncedAt, int progressMeters
});




}
/// @nodoc
class _$SelectedQuestCopyWithImpl<$Res>
    implements $SelectedQuestCopyWith<$Res> {
  _$SelectedQuestCopyWithImpl(this._self, this._then);

  final SelectedQuest _self;
  final $Res Function(SelectedQuest) _then;

/// Create a copy of SelectedQuest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? journeyId = null,Object? startedAt = null,Object? lastSyncedAt = null,Object? progressMeters = null,}) {
  return _then(SelectedQuest(
journeyId: null == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSyncedAt: null == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progressMeters: null == progressMeters ? _self.progressMeters : progressMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SelectedQuest].
extension SelectedQuestPatterns on SelectedQuest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SelectedQuest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectedQuest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SelectedQuest value)  $default,){
final _that = this;
switch (_that) {
case _SelectedQuest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SelectedQuest value)?  $default,){
final _that = this;
switch (_that) {
case _SelectedQuest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String journeyId,  DateTime startedAt,  DateTime lastSyncedAt,  int progressMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectedQuest() when $default != null:
return $default(_that.journeyId,_that.startedAt,_that.lastSyncedAt,_that.progressMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String journeyId,  DateTime startedAt,  DateTime lastSyncedAt,  int progressMeters)  $default,) {final _that = this;
switch (_that) {
case _SelectedQuest():
return $default(_that.journeyId,_that.startedAt,_that.lastSyncedAt,_that.progressMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String journeyId,  DateTime startedAt,  DateTime lastSyncedAt,  int progressMeters)?  $default,) {final _that = this;
switch (_that) {
case _SelectedQuest() when $default != null:
return $default(_that.journeyId,_that.startedAt,_that.lastSyncedAt,_that.progressMeters);case _:
  return null;

}
}

}

/// @nodoc


class _SelectedQuest implements SelectedQuest {
  const _SelectedQuest({required this.journeyId, required this.startedAt, required this.lastSyncedAt, required this.progressMeters});
  

@override final  String journeyId;
/// When the user tapped "Start quest".
@override final  DateTime startedAt;
/// Start of the sync window not yet applied to [progressMeters]. Seeded
/// to the start of the local calendar day on quest start (§5.2), so
/// steps already taken that day still count.
@override final  DateTime lastSyncedAt;
/// Total meters credited to this quest so far. Monotonically
/// non-decreasing — see `steps/domain/stride.dart`'s
/// `clampNonDecreasing`.
@override final  int progressMeters;

/// Create a copy of SelectedQuest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectedQuestCopyWith<_SelectedQuest> get copyWith => __$SelectedQuestCopyWithImpl<_SelectedQuest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectedQuest&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.progressMeters, progressMeters) || other.progressMeters == progressMeters));
}


@override
int get hashCode => Object.hash(runtimeType,journeyId,startedAt,lastSyncedAt,progressMeters);

@override
String toString() {
  return 'SelectedQuest(journeyId: $journeyId, startedAt: $startedAt, lastSyncedAt: $lastSyncedAt, progressMeters: $progressMeters)';
}


}

/// @nodoc
abstract mixin class _$SelectedQuestCopyWith<$Res> implements $SelectedQuestCopyWith<$Res> {
  factory _$SelectedQuestCopyWith(_SelectedQuest value, $Res Function(_SelectedQuest) _then) = __$SelectedQuestCopyWithImpl;
@override @useResult
$Res call({
 String journeyId, DateTime startedAt, DateTime lastSyncedAt, int progressMeters
});




}
/// @nodoc
class __$SelectedQuestCopyWithImpl<$Res>
    implements _$SelectedQuestCopyWith<$Res> {
  __$SelectedQuestCopyWithImpl(this._self, this._then);

  final _SelectedQuest _self;
  final $Res Function(_SelectedQuest) _then;

/// Create a copy of SelectedQuest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? journeyId = null,Object? startedAt = null,Object? lastSyncedAt = null,Object? progressMeters = null,}) {
  return _then(_SelectedQuest(
journeyId: null == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSyncedAt: null == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progressMeters: null == progressMeters ? _self.progressMeters : progressMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
