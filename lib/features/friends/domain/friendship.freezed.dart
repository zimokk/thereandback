// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friendship.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Friendship {

 String get pairId;/// Always exactly two uids, in the same sorted order [pairIdFor] would
/// produce — the repository and the Security Rules both rely on that.
 List<String> get uids; FriendshipStatus get status; String get initiatorUid; DateTime get createdAt; DateTime get updatedAt;/// uid -> hidden. A uid present with `true` means *that* user has chosen
/// to hide their own progress from the other party (§7: "может скрыть
/// свой прогресс от конкретного друга") — never the reverse.
 Map<String, bool> get hiddenBy;
/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendshipCopyWith<Friendship> get copyWith => _$FriendshipCopyWithImpl<Friendship>(this as Friendship, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Friendship&&(identical(other.pairId, pairId) || other.pairId == pairId)&&const DeepCollectionEquality().equals(other.uids, uids)&&(identical(other.status, status) || other.status == status)&&(identical(other.initiatorUid, initiatorUid) || other.initiatorUid == initiatorUid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.hiddenBy, hiddenBy));
}


@override
int get hashCode => Object.hash(runtimeType,pairId,const DeepCollectionEquality().hash(uids),status,initiatorUid,createdAt,updatedAt,const DeepCollectionEquality().hash(hiddenBy));

@override
String toString() {
  return 'Friendship(pairId: $pairId, uids: $uids, status: $status, initiatorUid: $initiatorUid, createdAt: $createdAt, updatedAt: $updatedAt, hiddenBy: $hiddenBy)';
}


}

/// @nodoc
abstract mixin class $FriendshipCopyWith<$Res>  {
  factory $FriendshipCopyWith(Friendship value, $Res Function(Friendship) _then) = _$FriendshipCopyWithImpl;
@useResult
$Res call({
 String pairId, List<String> uids, FriendshipStatus status, String initiatorUid, DateTime createdAt, DateTime updatedAt, Map<String, bool> hiddenBy
});




}
/// @nodoc
class _$FriendshipCopyWithImpl<$Res>
    implements $FriendshipCopyWith<$Res> {
  _$FriendshipCopyWithImpl(this._self, this._then);

  final Friendship _self;
  final $Res Function(Friendship) _then;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pairId = null,Object? uids = null,Object? status = null,Object? initiatorUid = null,Object? createdAt = null,Object? updatedAt = null,Object? hiddenBy = null,}) {
  return _then(Friendship(
pairId: null == pairId ? _self.pairId : pairId // ignore: cast_nullable_to_non_nullable
as String,uids: null == uids ? _self.uids : uids // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FriendshipStatus,initiatorUid: null == initiatorUid ? _self.initiatorUid : initiatorUid // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hiddenBy: null == hiddenBy ? _self.hiddenBy : hiddenBy // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [Friendship].
extension FriendshipPatterns on Friendship {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Friendship value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Friendship() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Friendship value)  $default,){
final _that = this;
switch (_that) {
case _Friendship():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Friendship value)?  $default,){
final _that = this;
switch (_that) {
case _Friendship() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String pairId,  List<String> uids,  FriendshipStatus status,  String initiatorUid,  DateTime createdAt,  DateTime updatedAt,  Map<String, bool> hiddenBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Friendship() when $default != null:
return $default(_that.pairId,_that.uids,_that.status,_that.initiatorUid,_that.createdAt,_that.updatedAt,_that.hiddenBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String pairId,  List<String> uids,  FriendshipStatus status,  String initiatorUid,  DateTime createdAt,  DateTime updatedAt,  Map<String, bool> hiddenBy)  $default,) {final _that = this;
switch (_that) {
case _Friendship():
return $default(_that.pairId,_that.uids,_that.status,_that.initiatorUid,_that.createdAt,_that.updatedAt,_that.hiddenBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String pairId,  List<String> uids,  FriendshipStatus status,  String initiatorUid,  DateTime createdAt,  DateTime updatedAt,  Map<String, bool> hiddenBy)?  $default,) {final _that = this;
switch (_that) {
case _Friendship() when $default != null:
return $default(_that.pairId,_that.uids,_that.status,_that.initiatorUid,_that.createdAt,_that.updatedAt,_that.hiddenBy);case _:
  return null;

}
}

}

/// @nodoc


class _Friendship extends Friendship {
  const _Friendship({required this.pairId, required  List<String> uids, required this.status, required this.initiatorUid, required this.createdAt, required this.updatedAt,  Map<String, bool> hiddenBy = const <String, bool>{}}): _uids = uids,_hiddenBy = hiddenBy,super._();
  

@override final  String pairId;
/// Always exactly two uids, in the same sorted order [pairIdFor] would
/// produce — the repository and the Security Rules both rely on that.
 final  List<String> _uids;
/// Always exactly two uids, in the same sorted order [pairIdFor] would
/// produce — the repository and the Security Rules both rely on that.
@override List<String> get uids {
  if (_uids is EqualUnmodifiableListView) return _uids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uids);
}

@override final  FriendshipStatus status;
@override final  String initiatorUid;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// uid -> hidden. A uid present with `true` means *that* user has chosen
/// to hide their own progress from the other party (§7: "может скрыть
/// свой прогресс от конкретного друга") — never the reverse.
 final  Map<String, bool> _hiddenBy;
/// uid -> hidden. A uid present with `true` means *that* user has chosen
/// to hide their own progress from the other party (§7: "может скрыть
/// свой прогресс от конкретного друга") — never the reverse.
@override@JsonKey() Map<String, bool> get hiddenBy {
  if (_hiddenBy is EqualUnmodifiableMapView) return _hiddenBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hiddenBy);
}


/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendshipCopyWith<_Friendship> get copyWith => __$FriendshipCopyWithImpl<_Friendship>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Friendship&&(identical(other.pairId, pairId) || other.pairId == pairId)&&const DeepCollectionEquality().equals(other._uids, _uids)&&(identical(other.status, status) || other.status == status)&&(identical(other.initiatorUid, initiatorUid) || other.initiatorUid == initiatorUid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._hiddenBy, _hiddenBy));
}


@override
int get hashCode => Object.hash(runtimeType,pairId,const DeepCollectionEquality().hash(_uids),status,initiatorUid,createdAt,updatedAt,const DeepCollectionEquality().hash(_hiddenBy));

@override
String toString() {
  return 'Friendship(pairId: $pairId, uids: $uids, status: $status, initiatorUid: $initiatorUid, createdAt: $createdAt, updatedAt: $updatedAt, hiddenBy: $hiddenBy)';
}


}

/// @nodoc
abstract mixin class _$FriendshipCopyWith<$Res> implements $FriendshipCopyWith<$Res> {
  factory _$FriendshipCopyWith(_Friendship value, $Res Function(_Friendship) _then) = __$FriendshipCopyWithImpl;
@override @useResult
$Res call({
 String pairId, List<String> uids, FriendshipStatus status, String initiatorUid, DateTime createdAt, DateTime updatedAt, Map<String, bool> hiddenBy
});




}
/// @nodoc
class __$FriendshipCopyWithImpl<$Res>
    implements _$FriendshipCopyWith<$Res> {
  __$FriendshipCopyWithImpl(this._self, this._then);

  final _Friendship _self;
  final $Res Function(_Friendship) _then;

/// Create a copy of Friendship
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pairId = null,Object? uids = null,Object? status = null,Object? initiatorUid = null,Object? createdAt = null,Object? updatedAt = null,Object? hiddenBy = null,}) {
  return _then(_Friendship(
pairId: null == pairId ? _self.pairId : pairId // ignore: cast_nullable_to_non_nullable
as String,uids: null == uids ? _self._uids : uids // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FriendshipStatus,initiatorUid: null == initiatorUid ? _self.initiatorUid : initiatorUid // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hiddenBy: null == hiddenBy ? _self._hiddenBy : hiddenBy // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}

// dart format on
