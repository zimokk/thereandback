// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_mapping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteVertex {

 double get x; double get y; int get cumulativeMeters;
/// Create a copy of RouteVertex
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteVertexCopyWith<RouteVertex> get copyWith => _$RouteVertexCopyWithImpl<RouteVertex>(this as RouteVertex, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteVertex&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.cumulativeMeters, cumulativeMeters) || other.cumulativeMeters == cumulativeMeters));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,cumulativeMeters);

@override
String toString() {
  return 'RouteVertex(x: $x, y: $y, cumulativeMeters: $cumulativeMeters)';
}


}

/// @nodoc
abstract mixin class $RouteVertexCopyWith<$Res>  {
  factory $RouteVertexCopyWith(RouteVertex value, $Res Function(RouteVertex) _then) = _$RouteVertexCopyWithImpl;
@useResult
$Res call({
 double x, double y, int cumulativeMeters
});




}
/// @nodoc
class _$RouteVertexCopyWithImpl<$Res>
    implements $RouteVertexCopyWith<$Res> {
  _$RouteVertexCopyWithImpl(this._self, this._then);

  final RouteVertex _self;
  final $Res Function(RouteVertex) _then;

/// Create a copy of RouteVertex
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? cumulativeMeters = null,}) {
  return _then(RouteVertex(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,cumulativeMeters: null == cumulativeMeters ? _self.cumulativeMeters : cumulativeMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteVertex].
extension RouteVertexPatterns on RouteVertex {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteVertex value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteVertex() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteVertex value)  $default,){
final _that = this;
switch (_that) {
case _RouteVertex():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteVertex value)?  $default,){
final _that = this;
switch (_that) {
case _RouteVertex() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y,  int cumulativeMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteVertex() when $default != null:
return $default(_that.x,_that.y,_that.cumulativeMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y,  int cumulativeMeters)  $default,) {final _that = this;
switch (_that) {
case _RouteVertex():
return $default(_that.x,_that.y,_that.cumulativeMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y,  int cumulativeMeters)?  $default,) {final _that = this;
switch (_that) {
case _RouteVertex() when $default != null:
return $default(_that.x,_that.y,_that.cumulativeMeters);case _:
  return null;

}
}

}

/// @nodoc


class _RouteVertex implements RouteVertex {
  const _RouteVertex({required this.x, required this.y, required this.cumulativeMeters});
  

@override final  double x;
@override final  double y;
@override final  int cumulativeMeters;

/// Create a copy of RouteVertex
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteVertexCopyWith<_RouteVertex> get copyWith => __$RouteVertexCopyWithImpl<_RouteVertex>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteVertex&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.cumulativeMeters, cumulativeMeters) || other.cumulativeMeters == cumulativeMeters));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,cumulativeMeters);

@override
String toString() {
  return 'RouteVertex(x: $x, y: $y, cumulativeMeters: $cumulativeMeters)';
}


}

/// @nodoc
abstract mixin class _$RouteVertexCopyWith<$Res> implements $RouteVertexCopyWith<$Res> {
  factory _$RouteVertexCopyWith(_RouteVertex value, $Res Function(_RouteVertex) _then) = __$RouteVertexCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, int cumulativeMeters
});




}
/// @nodoc
class __$RouteVertexCopyWithImpl<$Res>
    implements _$RouteVertexCopyWith<$Res> {
  __$RouteVertexCopyWithImpl(this._self, this._then);

  final _RouteVertex _self;
  final $Res Function(_RouteVertex) _then;

/// Create a copy of RouteVertex
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? cumulativeMeters = null,}) {
  return _then(_RouteVertex(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,cumulativeMeters: null == cumulativeMeters ? _self.cumulativeMeters : cumulativeMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$MapPoint {

 double get x; double get y;
/// Create a copy of MapPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPointCopyWith<MapPoint> get copyWith => _$MapPointCopyWithImpl<MapPoint>(this as MapPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'MapPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $MapPointCopyWith<$Res>  {
  factory $MapPointCopyWith(MapPoint value, $Res Function(MapPoint) _then) = _$MapPointCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$MapPointCopyWithImpl<$Res>
    implements $MapPointCopyWith<$Res> {
  _$MapPointCopyWithImpl(this._self, this._then);

  final MapPoint _self;
  final $Res Function(MapPoint) _then;

/// Create a copy of MapPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(MapPoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MapPoint].
extension MapPointPatterns on MapPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPoint value)  $default,){
final _that = this;
switch (_that) {
case _MapPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPoint value)?  $default,){
final _that = this;
switch (_that) {
case _MapPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPoint() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _MapPoint():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _MapPoint() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc


class _MapPoint implements MapPoint {
  const _MapPoint({required this.x, required this.y});
  

@override final  double x;
@override final  double y;

/// Create a copy of MapPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPointCopyWith<_MapPoint> get copyWith => __$MapPointCopyWithImpl<_MapPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'MapPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$MapPointCopyWith<$Res> implements $MapPointCopyWith<$Res> {
  factory _$MapPointCopyWith(_MapPoint value, $Res Function(_MapPoint) _then) = __$MapPointCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$MapPointCopyWithImpl<$Res>
    implements _$MapPointCopyWith<$Res> {
  __$MapPointCopyWithImpl(this._self, this._then);

  final _MapPoint _self;
  final $Res Function(_MapPoint) _then;

/// Create a copy of MapPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_MapPoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$RoutePolyline {

 List<RouteVertex> get vertices;
/// Create a copy of RoutePolyline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutePolylineCopyWith<RoutePolyline> get copyWith => _$RoutePolylineCopyWithImpl<RoutePolyline>(this as RoutePolyline, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutePolyline&&const DeepCollectionEquality().equals(other.vertices, vertices));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(vertices));

@override
String toString() {
  return 'RoutePolyline(vertices: $vertices)';
}


}

/// @nodoc
abstract mixin class $RoutePolylineCopyWith<$Res>  {
  factory $RoutePolylineCopyWith(RoutePolyline value, $Res Function(RoutePolyline) _then) = _$RoutePolylineCopyWithImpl;
@useResult
$Res call({
 List<RouteVertex> vertices
});




}
/// @nodoc
class _$RoutePolylineCopyWithImpl<$Res>
    implements $RoutePolylineCopyWith<$Res> {
  _$RoutePolylineCopyWithImpl(this._self, this._then);

  final RoutePolyline _self;
  final $Res Function(RoutePolyline) _then;

/// Create a copy of RoutePolyline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vertices = null,}) {
  return _then(RoutePolyline(
vertices: null == vertices ? _self.vertices : vertices // ignore: cast_nullable_to_non_nullable
as List<RouteVertex>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutePolyline].
extension RoutePolylinePatterns on RoutePolyline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutePolyline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutePolyline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutePolyline value)  $default,){
final _that = this;
switch (_that) {
case _RoutePolyline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutePolyline value)?  $default,){
final _that = this;
switch (_that) {
case _RoutePolyline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RouteVertex> vertices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutePolyline() when $default != null:
return $default(_that.vertices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RouteVertex> vertices)  $default,) {final _that = this;
switch (_that) {
case _RoutePolyline():
return $default(_that.vertices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RouteVertex> vertices)?  $default,) {final _that = this;
switch (_that) {
case _RoutePolyline() when $default != null:
return $default(_that.vertices);case _:
  return null;

}
}

}

/// @nodoc


class _RoutePolyline implements RoutePolyline {
  const _RoutePolyline({required  List<RouteVertex> vertices}): _vertices = vertices;
  

 final  List<RouteVertex> _vertices;
@override List<RouteVertex> get vertices {
  if (_vertices is EqualUnmodifiableListView) return _vertices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vertices);
}


/// Create a copy of RoutePolyline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutePolylineCopyWith<_RoutePolyline> get copyWith => __$RoutePolylineCopyWithImpl<_RoutePolyline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutePolyline&&const DeepCollectionEquality().equals(other._vertices, _vertices));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_vertices));

@override
String toString() {
  return 'RoutePolyline(vertices: $vertices)';
}


}

/// @nodoc
abstract mixin class _$RoutePolylineCopyWith<$Res> implements $RoutePolylineCopyWith<$Res> {
  factory _$RoutePolylineCopyWith(_RoutePolyline value, $Res Function(_RoutePolyline) _then) = __$RoutePolylineCopyWithImpl;
@override @useResult
$Res call({
 List<RouteVertex> vertices
});




}
/// @nodoc
class __$RoutePolylineCopyWithImpl<$Res>
    implements _$RoutePolylineCopyWith<$Res> {
  __$RoutePolylineCopyWithImpl(this._self, this._then);

  final _RoutePolyline _self;
  final $Res Function(_RoutePolyline) _then;

/// Create a copy of RoutePolyline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vertices = null,}) {
  return _then(_RoutePolyline(
vertices: null == vertices ? _self._vertices : vertices // ignore: cast_nullable_to_non_nullable
as List<RouteVertex>,
  ));
}


}

// dart format on
