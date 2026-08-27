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

/// @nodoc
mixin _$MapLandmark {

 String get id; String get name; double get x; double get y; int get meters;
/// Create a copy of MapLandmark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapLandmarkCopyWith<MapLandmark> get copyWith => _$MapLandmarkCopyWithImpl<MapLandmark>(this as MapLandmark, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapLandmark&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.meters, meters) || other.meters == meters));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,x,y,meters);

@override
String toString() {
  return 'MapLandmark(id: $id, name: $name, x: $x, y: $y, meters: $meters)';
}


}

/// @nodoc
abstract mixin class $MapLandmarkCopyWith<$Res>  {
  factory $MapLandmarkCopyWith(MapLandmark value, $Res Function(MapLandmark) _then) = _$MapLandmarkCopyWithImpl;
@useResult
$Res call({
 String id, String name, double x, double y, int meters
});




}
/// @nodoc
class _$MapLandmarkCopyWithImpl<$Res>
    implements $MapLandmarkCopyWith<$Res> {
  _$MapLandmarkCopyWithImpl(this._self, this._then);

  final MapLandmark _self;
  final $Res Function(MapLandmark) _then;

/// Create a copy of MapLandmark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? x = null,Object? y = null,Object? meters = null,}) {
  return _then(MapLandmark(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MapLandmark].
extension MapLandmarkPatterns on MapLandmark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapLandmark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapLandmark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapLandmark value)  $default,){
final _that = this;
switch (_that) {
case _MapLandmark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapLandmark value)?  $default,){
final _that = this;
switch (_that) {
case _MapLandmark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double x,  double y,  int meters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapLandmark() when $default != null:
return $default(_that.id,_that.name,_that.x,_that.y,_that.meters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double x,  double y,  int meters)  $default,) {final _that = this;
switch (_that) {
case _MapLandmark():
return $default(_that.id,_that.name,_that.x,_that.y,_that.meters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double x,  double y,  int meters)?  $default,) {final _that = this;
switch (_that) {
case _MapLandmark() when $default != null:
return $default(_that.id,_that.name,_that.x,_that.y,_that.meters);case _:
  return null;

}
}

}

/// @nodoc


class _MapLandmark implements MapLandmark {
  const _MapLandmark({required this.id, required this.name, required this.x, required this.y, required this.meters});
  

@override final  String id;
@override final  String name;
@override final  double x;
@override final  double y;
@override final  int meters;

/// Create a copy of MapLandmark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapLandmarkCopyWith<_MapLandmark> get copyWith => __$MapLandmarkCopyWithImpl<_MapLandmark>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapLandmark&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.meters, meters) || other.meters == meters));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,x,y,meters);

@override
String toString() {
  return 'MapLandmark(id: $id, name: $name, x: $x, y: $y, meters: $meters)';
}


}

/// @nodoc
abstract mixin class _$MapLandmarkCopyWith<$Res> implements $MapLandmarkCopyWith<$Res> {
  factory _$MapLandmarkCopyWith(_MapLandmark value, $Res Function(_MapLandmark) _then) = __$MapLandmarkCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double x, double y, int meters
});




}
/// @nodoc
class __$MapLandmarkCopyWithImpl<$Res>
    implements _$MapLandmarkCopyWith<$Res> {
  __$MapLandmarkCopyWithImpl(this._self, this._then);

  final _MapLandmark _self;
  final $Res Function(_MapLandmark) _then;

/// Create a copy of MapLandmark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? x = null,Object? y = null,Object? meters = null,}) {
  return _then(_MapLandmark(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$QuestMap {

 String get journeyId; String get imageAsset; int get imageWidth; int get imageHeight; int get totalMeters; RoutePolyline get polyline; List<MapLandmark> get landmarks;
/// Create a copy of QuestMap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestMapCopyWith<QuestMap> get copyWith => _$QuestMapCopyWithImpl<QuestMap>(this as QuestMap, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestMap&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight)&&(identical(other.totalMeters, totalMeters) || other.totalMeters == totalMeters)&&(identical(other.polyline, polyline) || other.polyline == polyline)&&const DeepCollectionEquality().equals(other.landmarks, landmarks));
}


@override
int get hashCode => Object.hash(runtimeType,journeyId,imageAsset,imageWidth,imageHeight,totalMeters,polyline,const DeepCollectionEquality().hash(landmarks));

@override
String toString() {
  return 'QuestMap(journeyId: $journeyId, imageAsset: $imageAsset, imageWidth: $imageWidth, imageHeight: $imageHeight, totalMeters: $totalMeters, polyline: $polyline, landmarks: $landmarks)';
}


}

/// @nodoc
abstract mixin class $QuestMapCopyWith<$Res>  {
  factory $QuestMapCopyWith(QuestMap value, $Res Function(QuestMap) _then) = _$QuestMapCopyWithImpl;
@useResult
$Res call({
 String journeyId, String imageAsset, int imageWidth, int imageHeight, int totalMeters, RoutePolyline polyline, List<MapLandmark> landmarks
});


$RoutePolylineCopyWith<$Res> get polyline;

}
/// @nodoc
class _$QuestMapCopyWithImpl<$Res>
    implements $QuestMapCopyWith<$Res> {
  _$QuestMapCopyWithImpl(this._self, this._then);

  final QuestMap _self;
  final $Res Function(QuestMap) _then;

/// Create a copy of QuestMap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? journeyId = null,Object? imageAsset = null,Object? imageWidth = null,Object? imageHeight = null,Object? totalMeters = null,Object? polyline = null,Object? landmarks = null,}) {
  return _then(QuestMap(
journeyId: null == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String,imageAsset: null == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String,imageWidth: null == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int,imageHeight: null == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int,totalMeters: null == totalMeters ? _self.totalMeters : totalMeters // ignore: cast_nullable_to_non_nullable
as int,polyline: null == polyline ? _self.polyline : polyline // ignore: cast_nullable_to_non_nullable
as RoutePolyline,landmarks: null == landmarks ? _self.landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as List<MapLandmark>,
  ));
}
/// Create a copy of QuestMap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoutePolylineCopyWith<$Res> get polyline {
  
  return $RoutePolylineCopyWith<$Res>(_self.polyline, (value) {
    return _then(_self.copyWith(polyline: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuestMap].
extension QuestMapPatterns on QuestMap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestMap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestMap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestMap value)  $default,){
final _that = this;
switch (_that) {
case _QuestMap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestMap value)?  $default,){
final _that = this;
switch (_that) {
case _QuestMap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String journeyId,  String imageAsset,  int imageWidth,  int imageHeight,  int totalMeters,  RoutePolyline polyline,  List<MapLandmark> landmarks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestMap() when $default != null:
return $default(_that.journeyId,_that.imageAsset,_that.imageWidth,_that.imageHeight,_that.totalMeters,_that.polyline,_that.landmarks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String journeyId,  String imageAsset,  int imageWidth,  int imageHeight,  int totalMeters,  RoutePolyline polyline,  List<MapLandmark> landmarks)  $default,) {final _that = this;
switch (_that) {
case _QuestMap():
return $default(_that.journeyId,_that.imageAsset,_that.imageWidth,_that.imageHeight,_that.totalMeters,_that.polyline,_that.landmarks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String journeyId,  String imageAsset,  int imageWidth,  int imageHeight,  int totalMeters,  RoutePolyline polyline,  List<MapLandmark> landmarks)?  $default,) {final _that = this;
switch (_that) {
case _QuestMap() when $default != null:
return $default(_that.journeyId,_that.imageAsset,_that.imageWidth,_that.imageHeight,_that.totalMeters,_that.polyline,_that.landmarks);case _:
  return null;

}
}

}

/// @nodoc


class _QuestMap implements QuestMap {
  const _QuestMap({required this.journeyId, required this.imageAsset, required this.imageWidth, required this.imageHeight, required this.totalMeters, required this.polyline, required  List<MapLandmark> landmarks}): _landmarks = landmarks;
  

@override final  String journeyId;
@override final  String imageAsset;
@override final  int imageWidth;
@override final  int imageHeight;
@override final  int totalMeters;
@override final  RoutePolyline polyline;
 final  List<MapLandmark> _landmarks;
@override List<MapLandmark> get landmarks {
  if (_landmarks is EqualUnmodifiableListView) return _landmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_landmarks);
}


/// Create a copy of QuestMap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestMapCopyWith<_QuestMap> get copyWith => __$QuestMapCopyWithImpl<_QuestMap>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestMap&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight)&&(identical(other.totalMeters, totalMeters) || other.totalMeters == totalMeters)&&(identical(other.polyline, polyline) || other.polyline == polyline)&&const DeepCollectionEquality().equals(other._landmarks, _landmarks));
}


@override
int get hashCode => Object.hash(runtimeType,journeyId,imageAsset,imageWidth,imageHeight,totalMeters,polyline,const DeepCollectionEquality().hash(_landmarks));

@override
String toString() {
  return 'QuestMap(journeyId: $journeyId, imageAsset: $imageAsset, imageWidth: $imageWidth, imageHeight: $imageHeight, totalMeters: $totalMeters, polyline: $polyline, landmarks: $landmarks)';
}


}

/// @nodoc
abstract mixin class _$QuestMapCopyWith<$Res> implements $QuestMapCopyWith<$Res> {
  factory _$QuestMapCopyWith(_QuestMap value, $Res Function(_QuestMap) _then) = __$QuestMapCopyWithImpl;
@override @useResult
$Res call({
 String journeyId, String imageAsset, int imageWidth, int imageHeight, int totalMeters, RoutePolyline polyline, List<MapLandmark> landmarks
});


@override $RoutePolylineCopyWith<$Res> get polyline;

}
/// @nodoc
class __$QuestMapCopyWithImpl<$Res>
    implements _$QuestMapCopyWith<$Res> {
  __$QuestMapCopyWithImpl(this._self, this._then);

  final _QuestMap _self;
  final $Res Function(_QuestMap) _then;

/// Create a copy of QuestMap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? journeyId = null,Object? imageAsset = null,Object? imageWidth = null,Object? imageHeight = null,Object? totalMeters = null,Object? polyline = null,Object? landmarks = null,}) {
  return _then(_QuestMap(
journeyId: null == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String,imageAsset: null == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String,imageWidth: null == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int,imageHeight: null == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int,totalMeters: null == totalMeters ? _self.totalMeters : totalMeters // ignore: cast_nullable_to_non_nullable
as int,polyline: null == polyline ? _self.polyline : polyline // ignore: cast_nullable_to_non_nullable
as RoutePolyline,landmarks: null == landmarks ? _self._landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as List<MapLandmark>,
  ));
}

/// Create a copy of QuestMap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoutePolylineCopyWith<$Res> get polyline {
  
  return $RoutePolylineCopyWith<$Res>(_self.polyline, (value) {
    return _then(_self.copyWith(polyline: value));
  });
}
}

// dart format on
