// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journey.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Journey {

 String get id; String get name; String get pointA; String get pointB;/// Total route length in meters. Always a whole, non-negative number —
/// the domain never deals in fractional meters (§11).
 int get totalMeters;/// Which visual flavor (§6.5, §14) Настройки defaults to for this quest
/// when the user hasn't pinned an explicit override.
 AppThemeId get themeId;
/// Create a copy of Journey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneyCopyWith<Journey> get copyWith => _$JourneyCopyWithImpl<Journey>(this as Journey, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Journey&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.pointA, pointA) || other.pointA == pointA)&&(identical(other.pointB, pointB) || other.pointB == pointB)&&(identical(other.totalMeters, totalMeters) || other.totalMeters == totalMeters)&&(identical(other.themeId, themeId) || other.themeId == themeId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,pointA,pointB,totalMeters,themeId);

@override
String toString() {
  return 'Journey(id: $id, name: $name, pointA: $pointA, pointB: $pointB, totalMeters: $totalMeters, themeId: $themeId)';
}


}

/// @nodoc
abstract mixin class $JourneyCopyWith<$Res>  {
  factory $JourneyCopyWith(Journey value, $Res Function(Journey) _then) = _$JourneyCopyWithImpl;
@useResult
$Res call({
 String id, String name, String pointA, String pointB, int totalMeters, AppThemeId themeId
});




}
/// @nodoc
class _$JourneyCopyWithImpl<$Res>
    implements $JourneyCopyWith<$Res> {
  _$JourneyCopyWithImpl(this._self, this._then);

  final Journey _self;
  final $Res Function(Journey) _then;

/// Create a copy of Journey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? pointA = null,Object? pointB = null,Object? totalMeters = null,Object? themeId = null,}) {
  return _then(Journey(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pointA: null == pointA ? _self.pointA : pointA // ignore: cast_nullable_to_non_nullable
as String,pointB: null == pointB ? _self.pointB : pointB // ignore: cast_nullable_to_non_nullable
as String,totalMeters: null == totalMeters ? _self.totalMeters : totalMeters // ignore: cast_nullable_to_non_nullable
as int,themeId: null == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as AppThemeId,
  ));
}

}


/// Adds pattern-matching-related methods to [Journey].
extension JourneyPatterns on Journey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Journey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Journey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Journey value)  $default,){
final _that = this;
switch (_that) {
case _Journey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Journey value)?  $default,){
final _that = this;
switch (_that) {
case _Journey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String pointA,  String pointB,  int totalMeters,  AppThemeId themeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Journey() when $default != null:
return $default(_that.id,_that.name,_that.pointA,_that.pointB,_that.totalMeters,_that.themeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String pointA,  String pointB,  int totalMeters,  AppThemeId themeId)  $default,) {final _that = this;
switch (_that) {
case _Journey():
return $default(_that.id,_that.name,_that.pointA,_that.pointB,_that.totalMeters,_that.themeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String pointA,  String pointB,  int totalMeters,  AppThemeId themeId)?  $default,) {final _that = this;
switch (_that) {
case _Journey() when $default != null:
return $default(_that.id,_that.name,_that.pointA,_that.pointB,_that.totalMeters,_that.themeId);case _:
  return null;

}
}

}

/// @nodoc


class _Journey implements Journey {
  const _Journey({required this.id, required this.name, required this.pointA, required this.pointB, required this.totalMeters, required this.themeId});
  

@override final  String id;
@override final  String name;
@override final  String pointA;
@override final  String pointB;
/// Total route length in meters. Always a whole, non-negative number —
/// the domain never deals in fractional meters (§11).
@override final  int totalMeters;
/// Which visual flavor (§6.5, §14) Настройки defaults to for this quest
/// when the user hasn't pinned an explicit override.
@override final  AppThemeId themeId;

/// Create a copy of Journey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneyCopyWith<_Journey> get copyWith => __$JourneyCopyWithImpl<_Journey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Journey&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.pointA, pointA) || other.pointA == pointA)&&(identical(other.pointB, pointB) || other.pointB == pointB)&&(identical(other.totalMeters, totalMeters) || other.totalMeters == totalMeters)&&(identical(other.themeId, themeId) || other.themeId == themeId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,pointA,pointB,totalMeters,themeId);

@override
String toString() {
  return 'Journey(id: $id, name: $name, pointA: $pointA, pointB: $pointB, totalMeters: $totalMeters, themeId: $themeId)';
}


}

/// @nodoc
abstract mixin class _$JourneyCopyWith<$Res> implements $JourneyCopyWith<$Res> {
  factory _$JourneyCopyWith(_Journey value, $Res Function(_Journey) _then) = __$JourneyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String pointA, String pointB, int totalMeters, AppThemeId themeId
});




}
/// @nodoc
class __$JourneyCopyWithImpl<$Res>
    implements _$JourneyCopyWith<$Res> {
  __$JourneyCopyWithImpl(this._self, this._then);

  final _Journey _self;
  final $Res Function(_Journey) _then;

/// Create a copy of Journey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? pointA = null,Object? pointB = null,Object? totalMeters = null,Object? themeId = null,}) {
  return _then(_Journey(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pointA: null == pointA ? _self.pointA : pointA // ignore: cast_nullable_to_non_nullable
as String,pointB: null == pointB ? _self.pointB : pointB // ignore: cast_nullable_to_non_nullable
as String,totalMeters: null == totalMeters ? _self.totalMeters : totalMeters // ignore: cast_nullable_to_non_nullable
as int,themeId: null == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as AppThemeId,
  ));
}


}

// dart format on
