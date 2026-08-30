// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_achievement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyAchievementState {

 AchievementDef get def;/// Every local calendar day this threshold was reached, ascending.
/// Empty means never reached. Built directly from
/// `AchievementRepository.loadUnlocks` (this task's requirement —
/// trophies persisted in the DB) via [buildDailyAchievementStates],
/// never recomputed live from raw step history in presentation code.
 List<DateTime> get unlockedDates;
/// Create a copy of DailyAchievementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyAchievementStateCopyWith<DailyAchievementState> get copyWith => _$DailyAchievementStateCopyWithImpl<DailyAchievementState>(this as DailyAchievementState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyAchievementState&&(identical(other.def, def) || other.def == def)&&const DeepCollectionEquality().equals(other.unlockedDates, unlockedDates));
}


@override
int get hashCode => Object.hash(runtimeType,def,const DeepCollectionEquality().hash(unlockedDates));

@override
String toString() {
  return 'DailyAchievementState(def: $def, unlockedDates: $unlockedDates)';
}


}

/// @nodoc
abstract mixin class $DailyAchievementStateCopyWith<$Res>  {
  factory $DailyAchievementStateCopyWith(DailyAchievementState value, $Res Function(DailyAchievementState) _then) = _$DailyAchievementStateCopyWithImpl;
@useResult
$Res call({
 AchievementDef def, List<DateTime> unlockedDates
});


$AchievementDefCopyWith<$Res> get def;

}
/// @nodoc
class _$DailyAchievementStateCopyWithImpl<$Res>
    implements $DailyAchievementStateCopyWith<$Res> {
  _$DailyAchievementStateCopyWithImpl(this._self, this._then);

  final DailyAchievementState _self;
  final $Res Function(DailyAchievementState) _then;

/// Create a copy of DailyAchievementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? def = null,Object? unlockedDates = null,}) {
  return _then(DailyAchievementState(
def: null == def ? _self.def : def // ignore: cast_nullable_to_non_nullable
as AchievementDef,unlockedDates: null == unlockedDates ? _self.unlockedDates : unlockedDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,
  ));
}
/// Create a copy of DailyAchievementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AchievementDefCopyWith<$Res> get def {
  
  return $AchievementDefCopyWith<$Res>(_self.def, (value) {
    return _then(_self.copyWith(def: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailyAchievementState].
extension DailyAchievementStatePatterns on DailyAchievementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyAchievementState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyAchievementState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyAchievementState value)  $default,){
final _that = this;
switch (_that) {
case _DailyAchievementState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyAchievementState value)?  $default,){
final _that = this;
switch (_that) {
case _DailyAchievementState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AchievementDef def,  List<DateTime> unlockedDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyAchievementState() when $default != null:
return $default(_that.def,_that.unlockedDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AchievementDef def,  List<DateTime> unlockedDates)  $default,) {final _that = this;
switch (_that) {
case _DailyAchievementState():
return $default(_that.def,_that.unlockedDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AchievementDef def,  List<DateTime> unlockedDates)?  $default,) {final _that = this;
switch (_that) {
case _DailyAchievementState() when $default != null:
return $default(_that.def,_that.unlockedDates);case _:
  return null;

}
}

}

/// @nodoc


class _DailyAchievementState extends DailyAchievementState {
  const _DailyAchievementState({required this.def, required  List<DateTime> unlockedDates}): _unlockedDates = unlockedDates,super._();
  

@override final  AchievementDef def;
/// Every local calendar day this threshold was reached, ascending.
/// Empty means never reached. Built directly from
/// `AchievementRepository.loadUnlocks` (this task's requirement —
/// trophies persisted in the DB) via [buildDailyAchievementStates],
/// never recomputed live from raw step history in presentation code.
 final  List<DateTime> _unlockedDates;
/// Every local calendar day this threshold was reached, ascending.
/// Empty means never reached. Built directly from
/// `AchievementRepository.loadUnlocks` (this task's requirement —
/// trophies persisted in the DB) via [buildDailyAchievementStates],
/// never recomputed live from raw step history in presentation code.
@override List<DateTime> get unlockedDates {
  if (_unlockedDates is EqualUnmodifiableListView) return _unlockedDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unlockedDates);
}


/// Create a copy of DailyAchievementState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyAchievementStateCopyWith<_DailyAchievementState> get copyWith => __$DailyAchievementStateCopyWithImpl<_DailyAchievementState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyAchievementState&&(identical(other.def, def) || other.def == def)&&const DeepCollectionEquality().equals(other._unlockedDates, _unlockedDates));
}


@override
int get hashCode => Object.hash(runtimeType,def,const DeepCollectionEquality().hash(_unlockedDates));

@override
String toString() {
  return 'DailyAchievementState(def: $def, unlockedDates: $unlockedDates)';
}


}

/// @nodoc
abstract mixin class _$DailyAchievementStateCopyWith<$Res> implements $DailyAchievementStateCopyWith<$Res> {
  factory _$DailyAchievementStateCopyWith(_DailyAchievementState value, $Res Function(_DailyAchievementState) _then) = __$DailyAchievementStateCopyWithImpl;
@override @useResult
$Res call({
 AchievementDef def, List<DateTime> unlockedDates
});


@override $AchievementDefCopyWith<$Res> get def;

}
/// @nodoc
class __$DailyAchievementStateCopyWithImpl<$Res>
    implements _$DailyAchievementStateCopyWith<$Res> {
  __$DailyAchievementStateCopyWithImpl(this._self, this._then);

  final _DailyAchievementState _self;
  final $Res Function(_DailyAchievementState) _then;

/// Create a copy of DailyAchievementState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? def = null,Object? unlockedDates = null,}) {
  return _then(_DailyAchievementState(
def: null == def ? _self.def : def // ignore: cast_nullable_to_non_nullable
as AchievementDef,unlockedDates: null == unlockedDates ? _self._unlockedDates : unlockedDates // ignore: cast_nullable_to_non_nullable
as List<DateTime>,
  ));
}

/// Create a copy of DailyAchievementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AchievementDefCopyWith<$Res> get def {
  
  return $AchievementDefCopyWith<$Res>(_self.def, (value) {
    return _then(_self.copyWith(def: value));
  });
}
}

// dart format on
