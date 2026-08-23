// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'steps_sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StepsSyncState {

 StepsPermissionStatus get permissionStatus; bool get isSyncing;/// Whether the most recent sync's interval exceeded the §5.2 realistic
/// pace threshold (`stride.isImplausiblePace`). The distance is still
/// credited either way — §5.2 requires flagging, never silently
/// dropping — this is only a signal for the UI to show a notice.
 bool get lastSyncFlagged;
/// Create a copy of StepsSyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepsSyncStateCopyWith<StepsSyncState> get copyWith => _$StepsSyncStateCopyWithImpl<StepsSyncState>(this as StepsSyncState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepsSyncState&&(identical(other.permissionStatus, permissionStatus) || other.permissionStatus == permissionStatus)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&(identical(other.lastSyncFlagged, lastSyncFlagged) || other.lastSyncFlagged == lastSyncFlagged));
}


@override
int get hashCode => Object.hash(runtimeType,permissionStatus,isSyncing,lastSyncFlagged);

@override
String toString() {
  return 'StepsSyncState(permissionStatus: $permissionStatus, isSyncing: $isSyncing, lastSyncFlagged: $lastSyncFlagged)';
}


}

/// @nodoc
abstract mixin class $StepsSyncStateCopyWith<$Res>  {
  factory $StepsSyncStateCopyWith(StepsSyncState value, $Res Function(StepsSyncState) _then) = _$StepsSyncStateCopyWithImpl;
@useResult
$Res call({
 StepsPermissionStatus permissionStatus, bool isSyncing, bool lastSyncFlagged
});




}
/// @nodoc
class _$StepsSyncStateCopyWithImpl<$Res>
    implements $StepsSyncStateCopyWith<$Res> {
  _$StepsSyncStateCopyWithImpl(this._self, this._then);

  final StepsSyncState _self;
  final $Res Function(StepsSyncState) _then;

/// Create a copy of StepsSyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? permissionStatus = null,Object? isSyncing = null,Object? lastSyncFlagged = null,}) {
  return _then(StepsSyncState(
permissionStatus: null == permissionStatus ? _self.permissionStatus : permissionStatus // ignore: cast_nullable_to_non_nullable
as StepsPermissionStatus,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,lastSyncFlagged: null == lastSyncFlagged ? _self.lastSyncFlagged : lastSyncFlagged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StepsSyncState].
extension StepsSyncStatePatterns on StepsSyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StepsSyncState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StepsSyncState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StepsSyncState value)  $default,){
final _that = this;
switch (_that) {
case _StepsSyncState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StepsSyncState value)?  $default,){
final _that = this;
switch (_that) {
case _StepsSyncState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StepsPermissionStatus permissionStatus,  bool isSyncing,  bool lastSyncFlagged)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StepsSyncState() when $default != null:
return $default(_that.permissionStatus,_that.isSyncing,_that.lastSyncFlagged);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StepsPermissionStatus permissionStatus,  bool isSyncing,  bool lastSyncFlagged)  $default,) {final _that = this;
switch (_that) {
case _StepsSyncState():
return $default(_that.permissionStatus,_that.isSyncing,_that.lastSyncFlagged);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StepsPermissionStatus permissionStatus,  bool isSyncing,  bool lastSyncFlagged)?  $default,) {final _that = this;
switch (_that) {
case _StepsSyncState() when $default != null:
return $default(_that.permissionStatus,_that.isSyncing,_that.lastSyncFlagged);case _:
  return null;

}
}

}

/// @nodoc


class _StepsSyncState implements StepsSyncState {
  const _StepsSyncState({this.permissionStatus = StepsPermissionStatus.unknown, this.isSyncing = false, this.lastSyncFlagged = false});
  

@override@JsonKey() final  StepsPermissionStatus permissionStatus;
@override@JsonKey() final  bool isSyncing;
/// Whether the most recent sync's interval exceeded the §5.2 realistic
/// pace threshold (`stride.isImplausiblePace`). The distance is still
/// credited either way — §5.2 requires flagging, never silently
/// dropping — this is only a signal for the UI to show a notice.
@override@JsonKey() final  bool lastSyncFlagged;

/// Create a copy of StepsSyncState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StepsSyncStateCopyWith<_StepsSyncState> get copyWith => __$StepsSyncStateCopyWithImpl<_StepsSyncState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StepsSyncState&&(identical(other.permissionStatus, permissionStatus) || other.permissionStatus == permissionStatus)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&(identical(other.lastSyncFlagged, lastSyncFlagged) || other.lastSyncFlagged == lastSyncFlagged));
}


@override
int get hashCode => Object.hash(runtimeType,permissionStatus,isSyncing,lastSyncFlagged);

@override
String toString() {
  return 'StepsSyncState(permissionStatus: $permissionStatus, isSyncing: $isSyncing, lastSyncFlagged: $lastSyncFlagged)';
}


}

/// @nodoc
abstract mixin class _$StepsSyncStateCopyWith<$Res> implements $StepsSyncStateCopyWith<$Res> {
  factory _$StepsSyncStateCopyWith(_StepsSyncState value, $Res Function(_StepsSyncState) _then) = __$StepsSyncStateCopyWithImpl;
@override @useResult
$Res call({
 StepsPermissionStatus permissionStatus, bool isSyncing, bool lastSyncFlagged
});




}
/// @nodoc
class __$StepsSyncStateCopyWithImpl<$Res>
    implements _$StepsSyncStateCopyWith<$Res> {
  __$StepsSyncStateCopyWithImpl(this._self, this._then);

  final _StepsSyncState _self;
  final $Res Function(_StepsSyncState) _then;

/// Create a copy of StepsSyncState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? permissionStatus = null,Object? isSyncing = null,Object? lastSyncFlagged = null,}) {
  return _then(_StepsSyncState(
permissionStatus: null == permissionStatus ? _self.permissionStatus : permissionStatus // ignore: cast_nullable_to_non_nullable
as StepsPermissionStatus,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,lastSyncFlagged: null == lastSyncFlagged ? _self.lastSyncFlagged : lastSyncFlagged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
