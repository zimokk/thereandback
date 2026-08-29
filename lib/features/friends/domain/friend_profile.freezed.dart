// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FriendProfile {

 String get uid; String get nickname; int get avatarPresetIndex;
/// Create a copy of FriendProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendProfileCopyWith<FriendProfile> get copyWith => _$FriendProfileCopyWithImpl<FriendProfile>(this as FriendProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FriendProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.avatarPresetIndex, avatarPresetIndex) || other.avatarPresetIndex == avatarPresetIndex));
}


@override
int get hashCode => Object.hash(runtimeType,uid,nickname,avatarPresetIndex);

@override
String toString() {
  return 'FriendProfile(uid: $uid, nickname: $nickname, avatarPresetIndex: $avatarPresetIndex)';
}


}

/// @nodoc
abstract mixin class $FriendProfileCopyWith<$Res>  {
  factory $FriendProfileCopyWith(FriendProfile value, $Res Function(FriendProfile) _then) = _$FriendProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String nickname, int avatarPresetIndex
});




}
/// @nodoc
class _$FriendProfileCopyWithImpl<$Res>
    implements $FriendProfileCopyWith<$Res> {
  _$FriendProfileCopyWithImpl(this._self, this._then);

  final FriendProfile _self;
  final $Res Function(FriendProfile) _then;

/// Create a copy of FriendProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? nickname = null,Object? avatarPresetIndex = null,}) {
  return _then(FriendProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,avatarPresetIndex: null == avatarPresetIndex ? _self.avatarPresetIndex : avatarPresetIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FriendProfile].
extension FriendProfilePatterns on FriendProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FriendProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FriendProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FriendProfile value)  $default,){
final _that = this;
switch (_that) {
case _FriendProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FriendProfile value)?  $default,){
final _that = this;
switch (_that) {
case _FriendProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String nickname,  int avatarPresetIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FriendProfile() when $default != null:
return $default(_that.uid,_that.nickname,_that.avatarPresetIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String nickname,  int avatarPresetIndex)  $default,) {final _that = this;
switch (_that) {
case _FriendProfile():
return $default(_that.uid,_that.nickname,_that.avatarPresetIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String nickname,  int avatarPresetIndex)?  $default,) {final _that = this;
switch (_that) {
case _FriendProfile() when $default != null:
return $default(_that.uid,_that.nickname,_that.avatarPresetIndex);case _:
  return null;

}
}

}

/// @nodoc


class _FriendProfile implements FriendProfile {
  const _FriendProfile({required this.uid, required this.nickname, required this.avatarPresetIndex});
  

@override final  String uid;
@override final  String nickname;
@override final  int avatarPresetIndex;

/// Create a copy of FriendProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendProfileCopyWith<_FriendProfile> get copyWith => __$FriendProfileCopyWithImpl<_FriendProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FriendProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.avatarPresetIndex, avatarPresetIndex) || other.avatarPresetIndex == avatarPresetIndex));
}


@override
int get hashCode => Object.hash(runtimeType,uid,nickname,avatarPresetIndex);

@override
String toString() {
  return 'FriendProfile(uid: $uid, nickname: $nickname, avatarPresetIndex: $avatarPresetIndex)';
}


}

/// @nodoc
abstract mixin class _$FriendProfileCopyWith<$Res> implements $FriendProfileCopyWith<$Res> {
  factory _$FriendProfileCopyWith(_FriendProfile value, $Res Function(_FriendProfile) _then) = __$FriendProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String nickname, int avatarPresetIndex
});




}
/// @nodoc
class __$FriendProfileCopyWithImpl<$Res>
    implements _$FriendProfileCopyWith<$Res> {
  __$FriendProfileCopyWithImpl(this._self, this._then);

  final _FriendProfile _self;
  final $Res Function(_FriendProfile) _then;

/// Create a copy of FriendProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? nickname = null,Object? avatarPresetIndex = null,}) {
  return _then(_FriendProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,avatarPresetIndex: null == avatarPresetIndex ? _self.avatarPresetIndex : avatarPresetIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
