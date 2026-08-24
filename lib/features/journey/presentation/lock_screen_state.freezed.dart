// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lock_screen_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LockScreenState {

 bool get enabled; LockScreenPermissionStatus get permissionStatus; bool get isBusy;/// The `journeyId` [LockScreenChannel.start] was last called for, or
/// `null` if nothing is currently being shown. Lets the controller tell
/// "first display for this quest" (→ `start`) apart from "same quest,
/// new progress" (→ `update`) without asking the channel implementation
/// to track that itself — a future iOS `Activity`-based implementation
/// can rely on `start` never being called twice in a row for the same
/// quest.
 String? get activeJourneyId;
/// Create a copy of LockScreenState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LockScreenStateCopyWith<LockScreenState> get copyWith => _$LockScreenStateCopyWithImpl<LockScreenState>(this as LockScreenState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockScreenState&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.permissionStatus, permissionStatus) || other.permissionStatus == permissionStatus)&&(identical(other.isBusy, isBusy) || other.isBusy == isBusy)&&(identical(other.activeJourneyId, activeJourneyId) || other.activeJourneyId == activeJourneyId));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,permissionStatus,isBusy,activeJourneyId);

@override
String toString() {
  return 'LockScreenState(enabled: $enabled, permissionStatus: $permissionStatus, isBusy: $isBusy, activeJourneyId: $activeJourneyId)';
}


}

/// @nodoc
abstract mixin class $LockScreenStateCopyWith<$Res>  {
  factory $LockScreenStateCopyWith(LockScreenState value, $Res Function(LockScreenState) _then) = _$LockScreenStateCopyWithImpl;
@useResult
$Res call({
 bool enabled, LockScreenPermissionStatus permissionStatus, bool isBusy, String? activeJourneyId
});




}
/// @nodoc
class _$LockScreenStateCopyWithImpl<$Res>
    implements $LockScreenStateCopyWith<$Res> {
  _$LockScreenStateCopyWithImpl(this._self, this._then);

  final LockScreenState _self;
  final $Res Function(LockScreenState) _then;

/// Create a copy of LockScreenState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? permissionStatus = null,Object? isBusy = null,Object? activeJourneyId = freezed,}) {
  return _then(LockScreenState(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,permissionStatus: null == permissionStatus ? _self.permissionStatus : permissionStatus // ignore: cast_nullable_to_non_nullable
as LockScreenPermissionStatus,isBusy: null == isBusy ? _self.isBusy : isBusy // ignore: cast_nullable_to_non_nullable
as bool,activeJourneyId: freezed == activeJourneyId ? _self.activeJourneyId : activeJourneyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LockScreenState].
extension LockScreenStatePatterns on LockScreenState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LockScreenState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LockScreenState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LockScreenState value)  $default,){
final _that = this;
switch (_that) {
case _LockScreenState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LockScreenState value)?  $default,){
final _that = this;
switch (_that) {
case _LockScreenState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  LockScreenPermissionStatus permissionStatus,  bool isBusy,  String? activeJourneyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LockScreenState() when $default != null:
return $default(_that.enabled,_that.permissionStatus,_that.isBusy,_that.activeJourneyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  LockScreenPermissionStatus permissionStatus,  bool isBusy,  String? activeJourneyId)  $default,) {final _that = this;
switch (_that) {
case _LockScreenState():
return $default(_that.enabled,_that.permissionStatus,_that.isBusy,_that.activeJourneyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  LockScreenPermissionStatus permissionStatus,  bool isBusy,  String? activeJourneyId)?  $default,) {final _that = this;
switch (_that) {
case _LockScreenState() when $default != null:
return $default(_that.enabled,_that.permissionStatus,_that.isBusy,_that.activeJourneyId);case _:
  return null;

}
}

}

/// @nodoc


class _LockScreenState implements LockScreenState {
  const _LockScreenState({this.enabled = false, this.permissionStatus = LockScreenPermissionStatus.unknown, this.isBusy = false, this.activeJourneyId});
  

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  LockScreenPermissionStatus permissionStatus;
@override@JsonKey() final  bool isBusy;
/// The `journeyId` [LockScreenChannel.start] was last called for, or
/// `null` if nothing is currently being shown. Lets the controller tell
/// "first display for this quest" (→ `start`) apart from "same quest,
/// new progress" (→ `update`) without asking the channel implementation
/// to track that itself — a future iOS `Activity`-based implementation
/// can rely on `start` never being called twice in a row for the same
/// quest.
@override final  String? activeJourneyId;

/// Create a copy of LockScreenState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LockScreenStateCopyWith<_LockScreenState> get copyWith => __$LockScreenStateCopyWithImpl<_LockScreenState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LockScreenState&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.permissionStatus, permissionStatus) || other.permissionStatus == permissionStatus)&&(identical(other.isBusy, isBusy) || other.isBusy == isBusy)&&(identical(other.activeJourneyId, activeJourneyId) || other.activeJourneyId == activeJourneyId));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,permissionStatus,isBusy,activeJourneyId);

@override
String toString() {
  return 'LockScreenState(enabled: $enabled, permissionStatus: $permissionStatus, isBusy: $isBusy, activeJourneyId: $activeJourneyId)';
}


}

/// @nodoc
abstract mixin class _$LockScreenStateCopyWith<$Res> implements $LockScreenStateCopyWith<$Res> {
  factory _$LockScreenStateCopyWith(_LockScreenState value, $Res Function(_LockScreenState) _then) = __$LockScreenStateCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, LockScreenPermissionStatus permissionStatus, bool isBusy, String? activeJourneyId
});




}
/// @nodoc
class __$LockScreenStateCopyWithImpl<$Res>
    implements _$LockScreenStateCopyWith<$Res> {
  __$LockScreenStateCopyWithImpl(this._self, this._then);

  final _LockScreenState _self;
  final $Res Function(_LockScreenState) _then;

/// Create a copy of LockScreenState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? permissionStatus = null,Object? isBusy = null,Object? activeJourneyId = freezed,}) {
  return _then(_LockScreenState(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,permissionStatus: null == permissionStatus ? _self.permissionStatus : permissionStatus // ignore: cast_nullable_to_non_nullable
as LockScreenPermissionStatus,isBusy: null == isBusy ? _self.isBusy : isBusy // ignore: cast_nullable_to_non_nullable
as bool,activeJourneyId: freezed == activeJourneyId ? _self.activeJourneyId : activeJourneyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
