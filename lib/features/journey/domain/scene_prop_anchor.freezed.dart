// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_prop_anchor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScenePropAnchor {

 String get id; int get meters; String get asset; ScenePropLayer get layer;
/// Create a copy of ScenePropAnchor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenePropAnchorCopyWith<ScenePropAnchor> get copyWith => _$ScenePropAnchorCopyWithImpl<ScenePropAnchor>(this as ScenePropAnchor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenePropAnchor&&(identical(other.id, id) || other.id == id)&&(identical(other.meters, meters) || other.meters == meters)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.layer, layer) || other.layer == layer));
}


@override
int get hashCode => Object.hash(runtimeType,id,meters,asset,layer);

@override
String toString() {
  return 'ScenePropAnchor(id: $id, meters: $meters, asset: $asset, layer: $layer)';
}


}

/// @nodoc
abstract mixin class $ScenePropAnchorCopyWith<$Res>  {
  factory $ScenePropAnchorCopyWith(ScenePropAnchor value, $Res Function(ScenePropAnchor) _then) = _$ScenePropAnchorCopyWithImpl;
@useResult
$Res call({
 String id, int meters, String asset, ScenePropLayer layer
});




}
/// @nodoc
class _$ScenePropAnchorCopyWithImpl<$Res>
    implements $ScenePropAnchorCopyWith<$Res> {
  _$ScenePropAnchorCopyWithImpl(this._self, this._then);

  final ScenePropAnchor _self;
  final $Res Function(ScenePropAnchor) _then;

/// Create a copy of ScenePropAnchor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? meters = null,Object? asset = null,Object? layer = null,}) {
  return _then(ScenePropAnchor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as int,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,layer: null == layer ? _self.layer : layer // ignore: cast_nullable_to_non_nullable
as ScenePropLayer,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenePropAnchor].
extension ScenePropAnchorPatterns on ScenePropAnchor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenePropAnchor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenePropAnchor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenePropAnchor value)  $default,){
final _that = this;
switch (_that) {
case _ScenePropAnchor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenePropAnchor value)?  $default,){
final _that = this;
switch (_that) {
case _ScenePropAnchor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int meters,  String asset,  ScenePropLayer layer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenePropAnchor() when $default != null:
return $default(_that.id,_that.meters,_that.asset,_that.layer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int meters,  String asset,  ScenePropLayer layer)  $default,) {final _that = this;
switch (_that) {
case _ScenePropAnchor():
return $default(_that.id,_that.meters,_that.asset,_that.layer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int meters,  String asset,  ScenePropLayer layer)?  $default,) {final _that = this;
switch (_that) {
case _ScenePropAnchor() when $default != null:
return $default(_that.id,_that.meters,_that.asset,_that.layer);case _:
  return null;

}
}

}

/// @nodoc


class _ScenePropAnchor implements ScenePropAnchor {
  const _ScenePropAnchor({required this.id, required this.meters, required this.asset, required this.layer});
  

@override final  String id;
@override final  int meters;
@override final  String asset;
@override final  ScenePropLayer layer;

/// Create a copy of ScenePropAnchor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenePropAnchorCopyWith<_ScenePropAnchor> get copyWith => __$ScenePropAnchorCopyWithImpl<_ScenePropAnchor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenePropAnchor&&(identical(other.id, id) || other.id == id)&&(identical(other.meters, meters) || other.meters == meters)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.layer, layer) || other.layer == layer));
}


@override
int get hashCode => Object.hash(runtimeType,id,meters,asset,layer);

@override
String toString() {
  return 'ScenePropAnchor(id: $id, meters: $meters, asset: $asset, layer: $layer)';
}


}

/// @nodoc
abstract mixin class _$ScenePropAnchorCopyWith<$Res> implements $ScenePropAnchorCopyWith<$Res> {
  factory _$ScenePropAnchorCopyWith(_ScenePropAnchor value, $Res Function(_ScenePropAnchor) _then) = __$ScenePropAnchorCopyWithImpl;
@override @useResult
$Res call({
 String id, int meters, String asset, ScenePropLayer layer
});




}
/// @nodoc
class __$ScenePropAnchorCopyWithImpl<$Res>
    implements _$ScenePropAnchorCopyWith<$Res> {
  __$ScenePropAnchorCopyWithImpl(this._self, this._then);

  final _ScenePropAnchor _self;
  final $Res Function(_ScenePropAnchor) _then;

/// Create a copy of ScenePropAnchor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? meters = null,Object? asset = null,Object? layer = null,}) {
  return _then(_ScenePropAnchor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as int,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,layer: null == layer ? _self.layer : layer // ignore: cast_nullable_to_non_nullable
as ScenePropLayer,
  ));
}


}

// dart format on
