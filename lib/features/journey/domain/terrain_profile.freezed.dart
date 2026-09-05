// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'terrain_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TerrainPoint {

 int get meters; double get height;
/// Create a copy of TerrainPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerrainPointCopyWith<TerrainPoint> get copyWith => _$TerrainPointCopyWithImpl<TerrainPoint>(this as TerrainPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerrainPoint&&(identical(other.meters, meters) || other.meters == meters)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,meters,height);

@override
String toString() {
  return 'TerrainPoint(meters: $meters, height: $height)';
}


}

/// @nodoc
abstract mixin class $TerrainPointCopyWith<$Res>  {
  factory $TerrainPointCopyWith(TerrainPoint value, $Res Function(TerrainPoint) _then) = _$TerrainPointCopyWithImpl;
@useResult
$Res call({
 int meters, double height
});




}
/// @nodoc
class _$TerrainPointCopyWithImpl<$Res>
    implements $TerrainPointCopyWith<$Res> {
  _$TerrainPointCopyWithImpl(this._self, this._then);

  final TerrainPoint _self;
  final $Res Function(TerrainPoint) _then;

/// Create a copy of TerrainPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meters = null,Object? height = null,}) {
  return _then(TerrainPoint(
meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TerrainPoint].
extension TerrainPointPatterns on TerrainPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerrainPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerrainPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerrainPoint value)  $default,){
final _that = this;
switch (_that) {
case _TerrainPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerrainPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TerrainPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int meters,  double height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerrainPoint() when $default != null:
return $default(_that.meters,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int meters,  double height)  $default,) {final _that = this;
switch (_that) {
case _TerrainPoint():
return $default(_that.meters,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int meters,  double height)?  $default,) {final _that = this;
switch (_that) {
case _TerrainPoint() when $default != null:
return $default(_that.meters,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _TerrainPoint implements TerrainPoint {
  const _TerrainPoint({required this.meters, required this.height});
  

@override final  int meters;
@override final  double height;

/// Create a copy of TerrainPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerrainPointCopyWith<_TerrainPoint> get copyWith => __$TerrainPointCopyWithImpl<_TerrainPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerrainPoint&&(identical(other.meters, meters) || other.meters == meters)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,meters,height);

@override
String toString() {
  return 'TerrainPoint(meters: $meters, height: $height)';
}


}

/// @nodoc
abstract mixin class _$TerrainPointCopyWith<$Res> implements $TerrainPointCopyWith<$Res> {
  factory _$TerrainPointCopyWith(_TerrainPoint value, $Res Function(_TerrainPoint) _then) = __$TerrainPointCopyWithImpl;
@override @useResult
$Res call({
 int meters, double height
});




}
/// @nodoc
class __$TerrainPointCopyWithImpl<$Res>
    implements _$TerrainPointCopyWith<$Res> {
  __$TerrainPointCopyWithImpl(this._self, this._then);

  final _TerrainPoint _self;
  final $Res Function(_TerrainPoint) _then;

/// Create a copy of TerrainPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meters = null,Object? height = null,}) {
  return _then(_TerrainPoint(
meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TerrainProfile {

 List<TerrainPoint> get points;
/// Create a copy of TerrainProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerrainProfileCopyWith<TerrainProfile> get copyWith => _$TerrainProfileCopyWithImpl<TerrainProfile>(this as TerrainProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerrainProfile&&const DeepCollectionEquality().equals(other.points, points));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(points));

@override
String toString() {
  return 'TerrainProfile(points: $points)';
}


}

/// @nodoc
abstract mixin class $TerrainProfileCopyWith<$Res>  {
  factory $TerrainProfileCopyWith(TerrainProfile value, $Res Function(TerrainProfile) _then) = _$TerrainProfileCopyWithImpl;
@useResult
$Res call({
 List<TerrainPoint> points
});




}
/// @nodoc
class _$TerrainProfileCopyWithImpl<$Res>
    implements $TerrainProfileCopyWith<$Res> {
  _$TerrainProfileCopyWithImpl(this._self, this._then);

  final TerrainProfile _self;
  final $Res Function(TerrainProfile) _then;

/// Create a copy of TerrainProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,}) {
  return _then(TerrainProfile(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<TerrainPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [TerrainProfile].
extension TerrainProfilePatterns on TerrainProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerrainProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerrainProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerrainProfile value)  $default,){
final _that = this;
switch (_that) {
case _TerrainProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerrainProfile value)?  $default,){
final _that = this;
switch (_that) {
case _TerrainProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TerrainPoint> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerrainProfile() when $default != null:
return $default(_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TerrainPoint> points)  $default,) {final _that = this;
switch (_that) {
case _TerrainProfile():
return $default(_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TerrainPoint> points)?  $default,) {final _that = this;
switch (_that) {
case _TerrainProfile() when $default != null:
return $default(_that.points);case _:
  return null;

}
}

}

/// @nodoc


class _TerrainProfile implements TerrainProfile {
  const _TerrainProfile({required  List<TerrainPoint> points}): _points = points;
  

 final  List<TerrainPoint> _points;
@override List<TerrainPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of TerrainProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerrainProfileCopyWith<_TerrainProfile> get copyWith => __$TerrainProfileCopyWithImpl<_TerrainProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerrainProfile&&const DeepCollectionEquality().equals(other._points, _points));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_points));

@override
String toString() {
  return 'TerrainProfile(points: $points)';
}


}

/// @nodoc
abstract mixin class _$TerrainProfileCopyWith<$Res> implements $TerrainProfileCopyWith<$Res> {
  factory _$TerrainProfileCopyWith(_TerrainProfile value, $Res Function(_TerrainProfile) _then) = __$TerrainProfileCopyWithImpl;
@override @useResult
$Res call({
 List<TerrainPoint> points
});




}
/// @nodoc
class __$TerrainProfileCopyWithImpl<$Res>
    implements _$TerrainProfileCopyWith<$Res> {
  __$TerrainProfileCopyWithImpl(this._self, this._then);

  final _TerrainProfile _self;
  final $Res Function(_TerrainProfile) _then;

/// Create a copy of TerrainProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,}) {
  return _then(_TerrainProfile(
points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<TerrainPoint>,
  ));
}


}

// dart format on
